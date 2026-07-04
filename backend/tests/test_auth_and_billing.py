def token_for(client, email):
    r = client.post("/auth/login", json={"email": email, "password": "pw"})
    assert r.status_code == 200, r.text
    return r.json()["access_token"]


def auth(token):
    return {"Authorization": f"Bearer {token}"}


# ---- Registration security (the privilege-escalation fix) ----

def test_public_register_forces_resident_role(client, seeded):
    r = client.post("/auth/register", json={
        "email": "attacker@x.com", "password": "pw", "full_name": "A",
        "role": "secretary", "society_id": seeded["soc_a"],
    })
    assert r.status_code == 200
    assert r.json()["role"] == "resident"


def test_register_bad_society_returns_404(client, seeded):
    r = client.post("/auth/register", json={
        "email": "ghost@x.com", "password": "pw", "full_name": "G", "society_id": 9999,
    })
    assert r.status_code == 404


# ---- Authorization (the unauth-access + cross-society fix) ----

def test_admin_endpoints_reject_anonymous(client, seeded):
    for path in [f"/admin/dashboard/{seeded['soc_a']}",
                 f"/admin/directory/{seeded['soc_a']}",
                 f"/billing/defaulters/{seeded['soc_a']}",
                 f"/complaints/society/{seeded['soc_a']}"]:
        assert client.get(path).status_code == 401, path


def test_resident_cannot_reach_admin(client, seeded):
    t = token_for(client, "res_a@x.com")
    assert client.get(f"/admin/dashboard/{seeded['soc_a']}", headers=auth(t)).status_code == 403


def test_secretary_cannot_reach_other_society(client, seeded):
    t = token_for(client, "sec_a@x.com")
    assert client.get(f"/admin/dashboard/{seeded['soc_b']}", headers=auth(t)).status_code == 403


def test_secretary_reaches_own_society(client, seeded):
    t = token_for(client, "sec_a@x.com")
    assert client.get(f"/admin/dashboard/{seeded['soc_a']}", headers=auth(t)).status_code == 200


def test_resident_sees_own_flat_bills_only(client, seeded):
    t = token_for(client, "res_a@x.com")
    assert client.get(f"/billing/bills/flat/{seeded['flat']}", headers=auth(t)).status_code == 200


# ---- Payment correctness (the double-count fix) ----

def test_partial_payment_stays_partial(client, seeded):
    sec = token_for(client, "sec_a@x.com")
    res = token_for(client, "res_a@x.com")
    bill = client.post("/billing/bills", headers=auth(sec), json={
        "flat_id": seeded["flat"], "period_month": 5, "period_year": 2026,
        "amount": 3000, "due_date": "2026-05-10",
    }).json()

    client.post("/billing/payments", headers=auth(res),
                json={"bill_id": bill["id"], "amount": 1000, "method": "upi"})
    client.post("/billing/payments", headers=auth(res),
                json={"bill_id": bill["id"], "amount": 1000, "method": "upi"})

    bills = client.get(f"/billing/bills/flat/{seeded['flat']}", headers=auth(res)).json()
    b = next(x for x in bills if x["id"] == bill["id"])
    assert b["amount_paid"] == 2000
    assert b["status"] == "partial"  # not "paid" — the double-count bug would make this fail


def test_full_payment_marks_paid(client, seeded):
    sec = token_for(client, "sec_a@x.com")
    res = token_for(client, "res_a@x.com")
    bill = client.post("/billing/bills", headers=auth(sec), json={
        "flat_id": seeded["flat"], "period_month": 6, "period_year": 2026,
        "amount": 2000, "due_date": "2026-06-10",
    }).json()
    client.post("/billing/payments", headers=auth(res),
                json={"bill_id": bill["id"], "amount": 2000, "method": "upi"})
    bills = client.get(f"/billing/bills/flat/{seeded['flat']}", headers=auth(res)).json()
    assert next(x for x in bills if x["id"] == bill["id"])["status"] == "paid"


def test_negative_payment_rejected(client, seeded):
    sec = token_for(client, "sec_a@x.com")
    res = token_for(client, "res_a@x.com")
    bill = client.post("/billing/bills", headers=auth(sec), json={
        "flat_id": seeded["flat"], "period_month": 7, "period_year": 2026,
        "amount": 1000, "due_date": "2026-07-10",
    }).json()
    r = client.post("/billing/payments", headers=auth(res),
                    json={"bill_id": bill["id"], "amount": -50, "method": "upi"})
    assert r.status_code == 400


def test_cannot_delete_bill_with_payments(client, seeded):
    sec = token_for(client, "sec_a@x.com")
    res = token_for(client, "res_a@x.com")
    bill = client.post("/billing/bills", headers=auth(sec), json={
        "flat_id": seeded["flat"], "period_month": 8, "period_year": 2026,
        "amount": 1000, "due_date": "2026-08-10",
    }).json()
    client.post("/billing/payments", headers=auth(res),
                json={"bill_id": bill["id"], "amount": 500, "method": "upi"})
    assert client.delete(f"/billing/bills/{bill['id']}", headers=auth(sec)).status_code == 400


def test_document_upload_sanitizes_path_traversal(client, seeded):
    sec = token_for(client, "sec_a@x.com")
    r = client.post("/documents", headers=auth(sec),
                    data={"society_id": seeded["soc_a"], "category": "test", "title": "t"},
                    files={"file": ("../../escape.txt", b"x", "text/plain")})
    assert r.status_code == 200
    # Stored path must stay under the society's own upload dir.
    assert "escape.txt" in r.json()["file_path"]
    assert ".." not in r.json()["file_path"]
