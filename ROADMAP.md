# SocietyOS — Implementation Roadmap
**From business report → shipped product → ₹30 Cr ARR**
Owner: Saurabh | Base: Pune | Prepared: July 2026

---

## 0. North Star

> Become the AI operating system of record for Indian housing societies — starting with 5 pilot societies in Pune, reaching 100 paying societies in 12 months, and ₹3 Cr ARR in 24 months.

Everything below exists to answer one question at each stage: **"What is the smallest thing I can ship that a real secretary will use tomorrow, and what does it unlock next?"**

The 16-module vision in the business report is the destination, not the starting point. This roadmap sequences it so you're never building something nobody asked for yet.

---

## 1. Roadmap at a Glance

```
Month:        1    2    3    4    5    6    7    8    9   10   11   12   →   24
              │────Phase 1────│──Phase 2──│────Phase 3────│  Phase 4 (Yr2)  │
Product       ERP MVP + Vault   AI Layer     Operations Suite   Marketplace + Finance
Customers     5 pilots (free)   50 paid      200 paid           500 paid
Revenue       ₹0                ₹8-15L ARR   ₹50-60L ARR        ₹2-3 Cr ARR
Team          You + 1 dev + 1   +1 dev       +1 dev, +1 sales   +ops, +support
              designer
Gate to next  Pilots retained   20 paying    150 paying, <5%    500 societies,
phase         >80%, 5 testi-    societies,   monthly churn      marketplace live,
              monials           NPS >40                         raise decision
```

Full 5-year numbers stay as in the report (Section 4.3) — this document only locks in **Phase 1–3 execution detail**, because that's what determines whether Years 2-5 ever happen.

---

## 2. Phase 1 — Foundation (Month 1–3, ₹8L)

**Goal: 5 pilot societies actively using it daily, unprompted, by end of Month 3.**

### 2.1 Build scope (in order — do not parallelize beyond this)
1. **Member management** — flat/tower structure, owner + tenant records, role-based access (secretary/treasurer/committee/resident)
2. **Billing engine** — maintenance bill generation (per-flat, per-sqft, or flat-rate configs), late fee rules
3. **Collection tracking** — payment recording, Razorpay UPI integration, defaulter list + auto-reminders
4. **Basic accounting** — receipts/payments book, bank reconciliation view, exportable ledger
5. **Document vault** — upload, categorize, version, role-gated access, expiry alerts (pulled forward from Phase 3 in the original report — this is your #1 retention/switching-cost lever, build it from day one so pilots start accumulating lock-in immediately)
6. **Web portal** — responsive, secretary-first UI (mobile use is primary, most secretaries work from phone)

Explicitly **not** in Phase 1: AI features, WhatsApp bot, visitor management, marketplace, elections, AGM suite. Every one of those is worthless without 5 societies actually trusting you with their books first.

### 2.2 Team & setup (Week 1)
- Hire 1 full-stack dev (₹50K/mo) — React + Flask/Node + Postgres, per report's stack
- Hire 1 UI/UX designer (₹30K/mo), part-time/contract is fine for Phase 1
- You: product spec, pilot recruitment, weekly user interviews
- Set up: AWS Mumbai (India data residency from day 1 — don't retrofit this later), Postgres, Razorpay sandbox, GitHub repo, staging environment

### 2.3 Pilot recruitment (Week 1–2, run in parallel with build)
- Use PROPEX network to identify **10 candidate societies** (recruit 10 to land 5 committed — expect drop-off)
- Selection criteria: secretary is WhatsApp-literate, society has 50-150 flats (sweet spot — small enough to be simple, big enough that pain is real), committee is willing to give weekly feedback
- Offer: free for 6 months, white-glove onboarding, direct line to you
- Get a signed (even informal) commitment: "we'll enter our data and use this for real billing this cycle"

### 2.4 Weekly cadence, Month 1–3
- Week 1-4: Core ERP build (member mgmt, billing, collection)
- Week 5-8: Accounting + document vault, start onboarding first 2 pilots on partial feature set (don't wait for 100% complete — real usage surfaces real bugs)
- Week 9-12: Remaining 3 pilots onboarded, weekly bug-fix + feedback loop, prep for Phase 2 kickoff

### 2.5 Exit criteria (do not start Phase 2 until true)
- [ ] 5 societies have processed at least one full billing cycle end-to-end
- [ ] At least 3 secretaries using it weekly without you prompting them
- [ ] You've personally sat with each secretary once and watched them use it (not asked them — watched)
- [ ] 5 written/video testimonials or at least verbal willingness-to-pay confirmation
- [ ] Core data model (flats, bills, payments, documents) hasn't needed a breaking schema change in 3+ weeks — stability signal before layering AI on top

---

## 3. Phase 2 — AI Layer + Monetization (Month 4–6, ₹8L)

**Goal: 50 paying societies. First revenue.**

### 3.1 Build scope
1. **AI Secretary** (Claude API) — natural-language document generation starting with the single highest-value use case: AGM notices and circulars. Don't build a general chatbot first; build one killer workflow.
2. **AI Treasurer** (Claude API) — plain-English Q&A over the society's own financial data ("what's our defaulter total this quarter?"), budget variance flagging
3. **WhatsApp bot** (Gupshup/Twilio WhatsApp Business API) — bill reminders, payment confirmations, complaint intake. This is your adoption unlock per the report's own logic ("if secretary can use WhatsApp, they can use SocietyOS")
4. **Resident mobile app** (React Native) — view bill, pay, raise complaint, view notices
5. **AI Compliance alerts** — rule-based + AI-drafted alerts for Maharashtra CHS filing deadlines (start with a hardcoded compliance calendar, layer AI drafting on top)

### 3.2 Monetization goes live
- Convert pilots off free tier at Month 4-5 end (they've had 6 months by the report's own offer — creates a natural, non-awkward deadline)
- Launch Tier 1 (₹12K/yr) and Tier 2 (₹30K/yr) publicly
- Start Strategy 2 (Secretary Champion Network) and Strategy 3 (CA network) from the GTM plan — these are zero-CAC channels, activate them before paid ads

### 3.3 Exit criteria
- [ ] 20+ societies converted to paid (not just free pilots)
- [ ] NPS > 40 from active users
- [ ] AI Secretary feature used unprompted by 30%+ of active societies
- [ ] Payment collection via platform (not manual) crosses 50% of pilot societies' total collections
- [ ] Support load is sustainable at current team size (signal for whether ops hire is needed before Phase 3)

---

## 4. Phase 3 — Operations Suite (Month 7–12, ₹10L)

**Goal: 200 paying societies, ₹50-60L ARR.**

### 4.1 Build scope (prioritize by report's own module rating — build in this order)
1. **Complaint & Dispute Center** — highest stickiness-per-effort ratio (report's own analysis: problems drive adoption)
2. **AGM Suite** — every society needs this annually; time this to launch ahead of the AGM season (most Maharashtra societies hold AGMs Jul–Sep — build by Month 7-8 to catch this cycle)
3. **Election Manager** — build ahead of election-heavy years; check registrar data for how many Pune-area societies have elections due in the current window before committing full build effort here vs. later
4. **Visitor management** — lower differentiation, but table-stakes vs. MyGate/NoBrokerHood competitively; build a lean version
5. **Asset management** — basic version, tied to the document vault you already built

### 4.2 Hire
- +1 developer (feature velocity)
- +1 dedicated sales/BD person to run the Builder Partnership (Strategy 1) and CA network at scale — this is the highest-leverage GTM channel per the report's own math and shouldn't stay founder-only past 50-100 societies

### 4.3 Exit criteria
- [ ] 150+ paying societies, monthly churn < 5%
- [ ] At least one builder partnership live and producing >10 societies
- [ ] At least one CHS federation relationship established (even informal)
- [ ] Unit economics known: CAC per channel (builder referral vs. CA vs. secretary champion vs. paid ads) — this determines Phase 4 budget allocation

---

## 5. Phase 4 — Marketplace & Finance (Year 2, ₹20L)

Only start this once Phase 3 exit criteria are met — the marketplace (vendor commissions, FD/loan referrals) is where the real transaction revenue in Section 4.2 of the report comes from, but it needs supply-side density (500+ societies) to work as a marketplace at all. Building it earlier just produces an empty directory nobody uses.

- Vendor Marketplace (verified vendors, ratings, in-platform payment, 15-20% commission)
- Society Finance Center (FD comparison, NBFC loan referrals)
- Multi-city expansion beyond Pune (Mumbai/MMR next, per report's district-level TAM)
- Raise decision point: at 500 societies / ~₹2Cr ARR, evaluate whether to bootstrap further or raise Series A per report's Year 3+ target

---

## 6. Immediate Next 30 Days (start now)

This is the only section that needs to happen before anything else:

1. **Week 1**: Finalize tech stack decisions (lock: React + Flask/Node + Postgres + AWS Mumbai), set up repo/infra, post the dev + designer roles
2. **Week 1**: Draft pilot society shortlist of 10 from PROPEX contacts, start outreach calls
3. **Week 2**: Hire dev + designer, kick off member management + billing engine build
4. **Week 2-3**: Lock in 5 committed pilot societies with a real handshake agreement (free 6mo, data commitment)
5. **Week 4**: First internal demo of member management + billing to you and 1 friendly pilot secretary, gather raw reaction before building further

---

## 7. Phase Gates — the actual discipline

The single biggest risk in a report this ambitious (16 modules, 5 revenue streams) is building breadth before depth. The gate criteria in each phase above are the mechanism to prevent that. Rule: **if a phase's exit criteria aren't met, do not start the next phase's build — extend the current phase and fix retention/usage first.** Revenue and module count are lagging indicators; weekly active usage by real secretaries is the leading one.

---

## 8. What's deliberately deferred (and why)

- **AI Energy Manager, predictive maintenance, cross-society analytics** — need data volume from hundreds of societies to be worth anything; premature before Phase 4-5
- **White-label, multi-tower enterprise features** — needed only once you're selling to 500+ flat gated communities, which is a Phase 4+ segment
- **ISO 27001 certification** — report correctly times this for Year 2; don't over-invest in compliance theater before you have paying customers whose trust you're certifying for

---

*Source strategy detail (market sizing, competitor analysis, full revenue model, GTM channel scripts, tech stack rationale, risk register) lives in the original business report — this document is the execution layer on top of it.*
