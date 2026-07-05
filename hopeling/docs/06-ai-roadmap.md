# Hopeling - Future AI Roadmap
*Deliverable 20*

The AI Helper must be **trustworthy first, clever second** - misinformation about an injured animal or an "ethical" brand could cause real harm. Every phase below is built around verified sources and graceful uncertainty.

## Phase 1 - Grounded Q&A (RAG over the curated corpus) - v1.x
- **What:** `POST /ai/ask` answers "How can I help turtles?", "Is this brand ethical?", "Can I recycle this?" using retrieval-augmented generation over Hopeling's own vetted content (categories, actions, orgs, sources) plus a whitelist of authoritative sites (IUCN, NOAA, FAO, ASPCA).
- **Why RAG not raw LLM:** answers cite sources and can't drift into invention; if retrieval finds nothing confident, the assistant says "I'm not sure - here's a vetted org to ask" instead of guessing.
- **Guardrails:** every answer returns `sources[]`; a refusal path for medical/legal specifics; no graphic content.

## Phase 2 - Emergency triage (rules + AI hybrid) - v1.x
- **What:** intents like "I found an injured bird" short-circuit the LLM into a **deterministic triage flow** (species-agnostic first-aid do/don'ts) + a lookup of the nearest wildlife-rescue contacts by location.
- **Why hybrid:** in safety-critical moments, a scripted checklist authored with rescue orgs beats generative fluency. AI only classifies the intent and localizes; it never improvises medical advice.

## Phase 3 - Personalized coach - v2
- **What:** on-device signals (which causes, which actions completed, streak) drive a gentle next-best-action recommender: "You've done 3 ocean actions - ready for a medium one this weekend?"
- **How:** lightweight on-device ranking model over the action catalog; privacy-preserving (no raw behavior leaves the device unless the user syncs an account).
- **Ethic:** suggests, never nags; respects the Hope>Fear rule (no "you're falling behind").

## Phase 4 - Vision features (on-device ML) - v2
- **Species photo-ID:** point the camera at wildlife → identify + link to the category. Uses an on-device model (e.g., a MobileNet/EfficientNet fine-tune or an iNaturalist-derived model) so it works offline in the field.
- **Barcode brand-ethics scanner:** scan a product → surface palm-oil/cruelty-free/sustainable-seafood signals from vetted databases.
- **Why on-device:** field use with no signal + privacy (photos never uploaded by default).

## Phase 5 - Content operations copilot (internal) - v2+
- **What:** an admin-side assistant that drafts new category/action/story content from primary sources, always leaving a human editor to approve and attach citations before publish.
- **Why:** scales the "easy to add species/NGOs/countries" requirement without lowering the evidence bar - AI drafts, humans verify.

## Cross-cutting AI principles
1. **Cite or abstain.** No uncited claims; low confidence → hand off to a vetted org.
2. **Safety over eloquence.** Emergency and health flows are scripted/verified, not free-generated.
3. **Privacy by default.** Vision and personalization run on-device; nothing sensitive leaves without consent.
4. **Hope-aligned.** The assistant encourages and never guilt-trips, consistent with the whole product.
5. **Human-in-the-loop for content.** Generative help drafts; people approve.
