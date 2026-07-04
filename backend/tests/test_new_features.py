def token_for(client, email):
    r = client.post("/auth/login", json={"email": email, "password": "pw"})
    assert r.status_code == 200, r.text
    return r.json()["access_token"]


def auth(token):
    return {"Authorization": f"Bearer {token}"}


# ---- Visitors ----

def test_resident_preapproves_and_guard_checks_in_visitor(client, seeded):
    res = token_for(client, "res_a@x.com")
    guard = token_for(client, "guard_a@x.com")

    r = client.post("/visitors", headers=auth(res),
                    json={"flat_id": seeded["flat"], "name": "Delivery Guy", "purpose": "delivery"})
    assert r.status_code == 200
    vid = r.json()["id"]

    r = client.patch(f"/visitors/{vid}/status", headers=auth(guard), json={"status": "checked_in"})
    assert r.status_code == 200
    assert r.json()["status"] == "checked_in"


def test_resident_cannot_see_full_society_visitor_list(client, seeded):
    res = token_for(client, "res_a@x.com")
    assert client.get(f"/visitors/society/{seeded['soc_a']}", headers=auth(res)).status_code == 403


def test_guard_cannot_see_other_societys_visitors(client, seeded):
    guard = token_for(client, "guard_a@x.com")
    assert client.get(f"/visitors/society/{seeded['soc_b']}", headers=auth(guard)).status_code == 403


# ---- Vehicles ----

def test_add_and_list_vehicle(client, seeded):
    res = token_for(client, "res_a@x.com")
    sec = token_for(client, "sec_a@x.com")

    r = client.post("/vehicles", headers=auth(res),
                    json={"flat_id": seeded["flat"], "plate_number": "MH12AB1234", "vehicle_type": "car"})
    assert r.status_code == 200

    r = client.get(f"/vehicles/society/{seeded['soc_a']}", headers=auth(sec))
    assert r.status_code == 200
    assert len(r.json()) == 1


def test_resident_cannot_add_vehicle_to_flat_not_theirs(client, seeded, db):
    from app import models
    other_flat = models.Flat(tower_id=seeded["tower"], number="A-999")
    db.add(other_flat)
    db.commit()

    res = token_for(client, "res_a@x.com")
    r = client.post("/vehicles", headers=auth(res),
                    json={"flat_id": other_flat.id, "plate_number": "MH12ZZ0000", "vehicle_type": "car"})
    assert r.status_code == 403


# ---- Staff ----

def test_staff_lifecycle_add_verify_checkin_checkout(client, seeded):
    res = token_for(client, "res_a@x.com")
    sec = token_for(client, "sec_a@x.com")
    guard = token_for(client, "guard_a@x.com")

    r = client.post("/staff", headers=auth(res),
                    json={"flat_id": seeded["flat"], "full_name": "Maid", "role": "maid"})
    assert r.status_code == 200
    sid = r.json()["id"]
    assert r.json()["is_verified"] is False

    r = client.patch(f"/staff/{sid}/verify", headers=auth(sec), json={"is_verified": True})
    assert r.status_code == 200
    assert r.json()["is_verified"] is True

    r = client.post(f"/staff/{sid}/check-in", headers=auth(guard))
    assert r.status_code == 200

    # duplicate check-in must be rejected
    r = client.post(f"/staff/{sid}/check-in", headers=auth(guard))
    assert r.status_code == 400

    r = client.post(f"/staff/{sid}/check-out", headers=auth(guard))
    assert r.status_code == 200


def test_resident_cannot_verify_staff(client, seeded):
    res = token_for(client, "res_a@x.com")
    r = client.post("/staff", headers=auth(res),
                    json={"flat_id": seeded["flat"], "full_name": "Cook", "role": "cook"})
    sid = r.json()["id"]
    r = client.patch(f"/staff/{sid}/verify", headers=auth(res), json={"is_verified": True})
    assert r.status_code == 403


# ---- Amenities ----

def test_amenity_booking_and_overlap_rejection(client, seeded):
    sec = token_for(client, "sec_a@x.com")
    res = token_for(client, "res_a@x.com")

    r = client.post("/amenities", headers=auth(sec), json={"name": "Clubhouse", "capacity": 20})
    assert r.status_code == 200
    aid = r.json()["id"]

    r = client.post("/amenities/bookings", headers=auth(res), json={
        "amenity_id": aid, "flat_id": seeded["flat"],
        "booking_date": "2026-08-01", "start_time": "18:00", "end_time": "20:00",
    })
    assert r.status_code == 200

    # overlapping slot on the same date must be rejected
    r = client.post("/amenities/bookings", headers=auth(res), json={
        "amenity_id": aid, "flat_id": seeded["flat"],
        "booking_date": "2026-08-01", "start_time": "19:00", "end_time": "21:00",
    })
    assert r.status_code == 409

    # non-overlapping slot the same day is fine
    r = client.post("/amenities/bookings", headers=auth(res), json={
        "amenity_id": aid, "flat_id": seeded["flat"],
        "booking_date": "2026-08-01", "start_time": "20:00", "end_time": "21:00",
    })
    assert r.status_code == 200


def test_resident_cannot_create_amenity(client, seeded):
    res = token_for(client, "res_a@x.com")
    r = client.post("/amenities", headers=auth(res), json={"name": "Hack"})
    assert r.status_code == 403


# ---- SOS ----

def test_sos_raise_and_resolve(client, seeded):
    res = token_for(client, "res_a@x.com")
    guard = token_for(client, "guard_a@x.com")

    r = client.post("/sos", headers=auth(res), json={"flat_id": seeded["flat"], "message": "help"})
    assert r.status_code == 200
    assert r.json()["status"] == "active"

    r = client.get(f"/sos/society/{seeded['soc_a']}", headers=auth(guard))
    assert r.status_code == 200
    assert len(r.json()) == 1
    alert_id = r.json()[0]["id"]

    r = client.patch(f"/sos/{alert_id}/resolve", headers=auth(guard))
    assert r.status_code == 200
    assert r.json()["status"] == "resolved"

    # active_only filter should now exclude it
    r = client.get(f"/sos/society/{seeded['soc_a']}", headers=auth(guard))
    assert len(r.json()) == 0


def test_resident_cannot_see_society_sos_feed(client, seeded):
    res = token_for(client, "res_a@x.com")
    assert client.get(f"/sos/society/{seeded['soc_a']}", headers=auth(res)).status_code == 403


# ---- Polls ----

def test_poll_create_vote_and_revote(client, seeded):
    sec = token_for(client, "sec_a@x.com")
    res = token_for(client, "res_a@x.com")

    r = client.post("/polls", headers=auth(sec), json={
        "society_id": seeded["soc_a"], "question": "Repaint?", "options": ["Yes", "No"],
    })
    assert r.status_code == 200
    poll = r.json()
    yes_id = poll["options"][0]["id"]
    no_id = poll["options"][1]["id"]

    r = client.post(f"/polls/{poll['id']}/vote", headers=auth(res), json={"option_id": yes_id})
    assert r.status_code == 200
    options = {o["id"]: o["vote_count"] for o in r.json()["options"]}
    assert options[yes_id] == 1
    assert options[no_id] == 0

    # re-voting changes the vote rather than adding a second one
    r = client.post(f"/polls/{poll['id']}/vote", headers=auth(res), json={"option_id": no_id})
    assert r.status_code == 200
    options = {o["id"]: o["vote_count"] for o in r.json()["options"]}
    assert options[yes_id] == 0
    assert options[no_id] == 1


def test_poll_requires_at_least_two_options(client, seeded):
    sec = token_for(client, "sec_a@x.com")
    r = client.post("/polls", headers=auth(sec), json={
        "society_id": seeded["soc_a"], "question": "Bad poll", "options": ["Only one"],
    })
    assert r.status_code == 400


def test_resident_cannot_create_poll(client, seeded):
    res = token_for(client, "res_a@x.com")
    r = client.post("/polls", headers=auth(res), json={
        "society_id": seeded["soc_a"], "question": "Hack", "options": ["A", "B"],
    })
    assert r.status_code == 403
