# Hopeling: from an app to a company

*My notes, October 2026. Written for us, not for anyone else. Argue with every line.*

We have spent most of a year building. The Lab, the School, Kids mode, the Classroom Bench, this-not-that, the public pages. I am proud of all of it. But I have caught myself confusing a big product with a big company, and they are not the same thing. So I sat down and did the exercise properly: what do we actually have, who would pay for it, what is missing, and what would it take for me to get on a plane to San Diego with real meetings and come back with a pilot.

Where I quote a number, I link where it came from. Where I am guessing, I say so. I would rather we disprove half of this than believe all of it.

---

## 1. What we actually have

### What is genuinely special

Three things, and they are not the things our feature list would suggest.

**Our rules are in the code, not on a wall.** No points, no streaks, no scores, no fail states, no ads, no fake live data, no chatbot for children, every number dated and sourced, a child can never end in the ruins. Those are tests. They fail the build. Most companies have values in a slide deck. I think this matters more now than it did a year ago, because districts are visibly tired of engagement theater. A district leader was quoted this year saying "I've seen crazy metrics, like number of clicks" ([EdSurge](https://www.edsurge.com/news/2026-01-27-k-12-edtech-in-2026-five-trends-shaping-the-year-ahead)). That is the buyer we built for without knowing it.

**A real simulation with a classroom mode and lesson plans a teacher can run tomorrow.** Twelve honest ecosystem models, run three ways, with repair acts and thresholds, and a Bench that turns each one into a 45-minute lesson including the one thing lesson plans never print: what the room usually says first. Mystery Science and Generation Genius sell videos and worksheets. We sell a model the class can argue with. I have not found anything like it in the elementary science market.

**The loop closes.** Learn (the Lab) leads to a neighbour (the Atlas) leads to a decision (this-not-that) leads to an action (the shelf) leads to a measurement (the Long Record, which I still have to build). Everyone else does one of these. The loop is the product.

### Our strongest advantage

Honesty as a feature, packaged as six weeks a teacher can run without prep. Everything we refuse to do is exactly what a science coordinator is being told to cut this year. We are the tool that was built the way the buyer now wishes everything had been built. I want to say that sentence in every room.

### What would actually be hard to copy

I need to be honest with myself here. Nothing we have built is technically hard. A funded team could rebuild the Lab in a quarter. What they could not rebuild:

- **A school's own multi-year record.** A school with three years of first signs in Hopeling cannot leave without losing its own data. That is the only real moat on this page, and it does not exist yet. I have to build it.
- **The voice and the restraint.** The writing is the product, and it is the first thing a copier gets wrong, because they will add a leaderboard.
- **Public, cited, machine-readable knowledge.** The swaps pages and `/swaps.json` are the start of being a reference rather than an app. Reference status compounds. Features do not.

### What someone would actually pay for

In the order I think a signature is likely:

1. The six-week program (Bench + Lab + Errand + Long Record + the packet). A school or a county.
2. The Classroom Bench on its own, as a teacher tool. A teacher's own budget or a site fund.
3. An institution (aquarium, zoo, watershed nonprofit) licensing the program for its partner schools as "the take-home" of a field trip.
4. Kids mode as a family subscription. Later, after the school motion has given us a name.

Not on the list: the Hub, pet care, adoption, Circles, Wins, Explore's 28 worlds. I like all of them. No one will pay for them.

### What is missing

The uncomfortable part.

- **Evidence.** Zero classrooms. Zero teachers who have run a lesson. Zero data on whether a child learns anything. Everything in these notes depends on fixing this first.
- **A web build on Chromebooks.** American elementary classrooms run on Chromebooks and Google Classroom. A phone app is invisible to a teacher. The PWA at hopeling.app is a start; the School has to work there.
- **The trust pack.** A signed California Student Data Privacy Agreement, a privacy policy written for districts, a data map that says "we hold no student PII" and proves it, an accessibility statement, a security page, terms, a company entity, insurance. Districts will not pilot without most of this. The CSDPA is one template that covers FERPA, PPRA, COPPA, SOPIPA and AB 1584 together ([SDPC](https://sdpc.a4l.org/agreements/CSDPA_Book%20Creator.pdf)), and California's registry lets one district's signed copy be reused by others ([CSPA FAQ](https://assets.noviams.com/novi-file-uploads/cite/Resources/Docs/CSPA/CETPA_CSPA_FAQ_v3-e992ae43.pdf)). Sign one and the next fifty are easier.
- **A teacher's side.** Today a teacher can project the Bench. She cannot see which groups ran, keep a class record, print the packet, or share a link. There is no concept of a class in the app.
- **Enough for six weeks, not for a year.** Twelve experiments, eighteen signs, five bird voices, ten neighbours. A unit, not a curriculum. We should sell the unit and stop pretending otherwise.
- **Region.** Our birds are North American, our phenology is northern temperate. San Diego is Mediterranean: first rain, coastal sage in flower, gray whales passing in January. A week of content, but it has to happen before any trip.
- **A sales motion.** Nobody has ever been asked to pay. I do not know the objection list yet.

### Are we serving too many audiences?

Yes. Adults who want one small thing a day, children, parents, animal lovers, teachers, social groups, people who want good news. Seven audiences. A consumer app can get away with that. A company cannot.

### The focus

**Schools, through the six-week program, with institutions as the channel and the consumer app as the free front door.** The app stays free as proof of craft and as the thing a teacher downloads the night after a demo. Every building hour for the next six months goes to the school motion. Kids mode is the second business, two years out, paid for by the first.

---

## 2. How Hopeling gets big

Three routes. Two are real.

### A. The program, sold to schools, counties and districts

The unit of sale is the six-week program, not the app. A school buys something with a beginning, an end, a planted patch and a report. It fits a quarter, maps to NGSS (5-LS2-1, MS-LS2-4), fits California's environmental literacy push (the Blueprint, Green Ribbon Schools, and Ten Strands' Seeds to Solutions now free to every K-12 teacher ([Ten Strands](https://2025.tenstrands.org/), [CDE](https://www.cde.ca.gov/ci/pl/environliteracyblueprint.asp))), and produces something a principal can put in a newsletter.

The honest context: the ESSER money is gone, districts are consolidating, and anything duplicative or low-usage gets cut first ([Civic IQ](https://civiciq.com/blog/esser-budget-cliff-k12-edtech)). That kills "another app." It favors a bounded program with an outcome. We have to be the second thing.

### B. Institutions as the channel

Aquariums, zoos, natural history museums, watershed nonprofits and county outdoor-education programs already have the school relationships, the field-trip calendar, the mandate and, crucially, the funding. The Port of San Diego's environmental education program has reached about half a million students since 2003 through partners like I Love A Clean San Diego ([Port of San Diego](https://www.portofsandiego.org/environment/environmental-conservation/environmental-education-community-outreach)). Birch Aquarium runs Discovery Labs in classrooms and trains teachers on its own curriculum ([Birch](https://aquarium.ucsd.edu/newsroom/bite-size-science-big-impact)). SDCOE's Outdoor Education Outreach brings free K-8 science programs into schools, paid for by community partners ([SDCOE](https://www.sdcoe.net/educators/outdoor-education-outreach)).

Every one of them has the same gap: the day after the field trip, nothing. We are the day after. "Your students met the kelp forest with us. Here are the six weeks that follow, on their Chromebooks and in their schoolyard, with your name on it." An institution licenses the program, co-brands it, and hands it to a hundred schools we could never reach on our own. This is the fastest route to scale and the one we have thought about least. I think it might be the first contract we sign.

### C. The consumer app and Kids mode

Merlin has passed 40 million downloads ([Digital Trends](https://www.digitaltrends.com/cool-tech/merlin-bird-id-app-is-now-eyeing-a-global-database-of-our-vanishing-feathery-friends/)). iNaturalist has hundreds of millions of observations ([Wikipedia](https://en.wikipedia.org/wiki/INaturalist)). People want nature on a phone; that is proven. But both are free, built by institutions, with a decade's head start. A paid nature app for adults is not a business. A paid kids app is a business, but a brutal one: Khan Academy Kids is free and excellent, the median education subscription is about $35 a year ([RevenueCat](https://www.revenuecat.com/state-of-subscription-apps-2026-education)), and acquisition costs for family apps routinely exceed first-year revenue.

So the consumer app is the brand, not the business. Later, when a thousand teachers have sent a thousand parents to the Little Meadow, Kids mode becomes a subscription with free distribution. Not before.

### Is there a new category in here?

I think so, and the name for it is small: **the schoolyard record.** Not "environmental education software." A school that keeps a ten-year record of its own ground, kept by children, feeding the national phenology networks that already exist. Nobody owns that. It is the one thing in these notes that gets more valuable with time instead of less, which is why the Long Record goes before anything else that is not on the trust list.

---

## 3. Making a school say "we need this"

### What American elementary schools actually need

From the buyer-side reporting, not the vendor-side:

1. **Less teacher time, not more.** Elementary teachers are generalists with forty minutes of science a week if they are lucky. A product that needs a login per child, a training and a prep period dies. The Bench's "sentence for the board, what the room says first, three prompts" is exactly right. Every surface has to stay at that level.
2. **Standards and a local reason.** NGSS on paper, plus a hook: California's environmental literacy expectation, a Green Ribbon application, a watershed grant. We have both.
3. **Nothing that touches student data.** The best privacy posture is holding nothing. We can run the whole program with zero student accounts: the teacher projects, the class keeps one record, a child's own phone is their own. This goes in the first thirty seconds of every meeting.
4. **Chromebooks, Google Classroom, a link.** Not an App Store.
5. **Evidence it worked**, in a form a principal can forward: the before-and-after count, the planted patch, the children's own explanations.

### The problem we solve

Not "environmental education." Narrower: **elementary science is squeezed, outdoor learning is expected in spirit and unsupported in practice, and the teacher has no materials that get children outside and come back with evidence.** We hand her six weeks that do both, with no prep and no data risk.

### What I show in the room

The Classroom Bench, live, with the people in the room as the class. The sentence on the board. The principal raises her hand. Three benches on one clock. The room disagrees with the model. Then the repair act: in week five your fourth graders do this for real on your campus, and in week six they count what changed. That is the whole pitch. Eleven minutes.

### Purchasing, privacy, standards, budgets

- **Purchasing.** Pilots are free and informal; a principal can say yes. Paid site licenses under a few thousand dollars are usually within a principal's or a science coordinator's discretion. District purchases go through curriculum review, a privacy agreement, often a board item, and a cycle that decides in spring and pays in summer. I have to plan backwards from July.
- **Privacy.** The CSDPA in California, the national NDPA elsewhere. Sign once with the first district; it propagates. Plus a plain-English privacy policy, a named contact, a retention statement, a deletion process. There is pending legislation (AB 1159) that would sharpen protections further ([Assembly analysis](https://apcp.assembly.ca.gov/system/files/2026-01/ab-1159-addis-apcp-analysis.pdf)). Holding no student data is the posture that survives every version.
- **Standards.** NGSS performance expectations named per lesson (done in the program packet). For California, the Environmental Principles and Concepts woven in explicitly.
- **Accessibility.** WCAG 2.1 AA on the web build and a conformance statement. We already test tap targets and labels; say so.
- **Budgets.** Assume no new money. Price so a principal can pay from site funds, a PTA can sponsor a school, and an institution can fund ten schools from an existing grant.

### The teacher's side, as small as possible

A class code, a teacher link, the class record, a printable packet, projection. Nothing else. No gradebook. No engagement charts. The "dashboard" is the class record and the explanations the teacher typed in. That restraint is a selling point and I will say so.

---

## 4. The San Diego plan

### Why San Diego, honestly

Not because it is San Diego. Because my co-founder is in the US, it is a coastal city with an unusually dense environmental-education scene, California has a stated environmental literacy agenda, and the county office already runs outdoor science outreach and an Environmental Educator Leaders Network ([SDCOE](https://www.sdcoe.net/educators/curriculum-instruction/environmental-literacy)). Good reasons. Section 9 is where I admit they may not be enough on their own.

### Who to contact, in order

**Tier 1: people who already do this job and need the day-after.**

| Who | Why | The ask |
|---|---|---|
| SDCOE Environmental Literacy team and the Environmental Educator Leaders Network | County reach to every district; they run teacher PD on the EP&Cs and decide what gets into workshops. | A slot in a PD session; a county-endorsed pilot in three schools. |
| SDCOE Outdoor Education Outreach | Free K-8 science programs delivered into schools, funded by partners. We are the follow-up to their visit. | Bundle the program as their take-home. |
| Birch Aquarium at Scripps, education team | Classroom Discovery Labs, teacher training, NGSS-aligned, already in the classroom. | A co-branded program for their partner schools; a pilot in two. |
| I Love A Clean San Diego and the Port's EE program | Half a million students reached; watershed focus; our runoff experiment is their lesson. | Pilot the river unit with their partner schools. |
| Ocean Discovery Institute | City Heights youth, programs at no cost, mission-aligned. | A community pilot and a reference. |

**Tier 2: schools that would say yes quickly.**

| Who | Why |
|---|---|
| National School District | A 2026 California Green Ribbon Schools winner ([SDCOE](https://www.sdcoe.net/about-sdcoe/news/post/~board/news/post/national-school-district-named-a-2026-california-green-ribbon-schools-award-winner)). A district that has already decided this matters, small enough that the superintendent will take the meeting. The best first district in the county. |
| High Tech Elementary and the High Tech High network | Project-based learning is their identity; a fifth-grade intertidal project worked with Cabrillo National Monument ([HTH](https://www.hightechhigh.org/hte/project/life-by-the-tide/)). Our program is a project. |
| Santee School District | Renewed its county outdoor education agreement for 2026-27 ([board record](https://citizenportal.ai/articles/9346083/California/School-Districts/Santee/Board-approves-Outdoor-Education-agreement-for-202627-member-who-works-for-county-program-did-not-vote)). Already spending on outdoor learning. |
| One or two schools inside San Diego Unified, through a principal, not the district | Second-largest district in the state, focused this year on wellness, literacy and math ([SDUSD](https://www.sandiegounified.org/about/newscenter/all_news/2026_27_school_year_focused_on_student_goals)). I will not sell to the district. I will find one principal with a garden. |

**Tier 3, for later:** Ten Strands and CAELI statewide, the California Science Education Conference, AEOE, the Green California Schools Summit.

Not on the first trip: the Zoo (too big to move fast), the Natural History Museum (same), universities (long cycles), tech meetups (wrong room).

### What has to be true before I book a flight

1. The School surfaces running on a Chromebook from a link. Non-negotiable.
2. A San Diego sign shelf for the Long Record and a Pacific bird pack. One week of content.
3. The trust pack: privacy policy, data statement, CSDPA ready to sign, accessibility statement, an entity, insurance quotes.
4. One completed pilot anywhere. Six weeks, three classes, a teacher who will take a phone call. Where I live is fine. The pilot is the proof, not the location.
5. The packet, the deck, the one-pager, a three-minute film, a schools page on hopeling.app with a pilot request form.
6. Ten warm introductions. Through my co-founder's network, AEOE's members, the SDCOE team's public contacts, High Tech High's project pages.
7. Five confirmed meetings. Calendar invites, not "interest."

### Getting the meetings

Warm beats cold ten to one. First an email to the SDCOE environmental literacy lead asking for twenty minutes to show a classroom tool built around the EP&Cs, naming the Green Ribbon district. Then National School District, naming SDCOE. Then Birch's education director, naming both. Each email names the one before it. By the fourth, we are a thing people in the county have heard of.

### The email

> Subject: A six-week outdoor science unit built for the EP&Cs (12-minute demo)
>
> Hi [Name],
>
> I'm Yakir, co-founder of Hopeling. We've built a six-week "School as an Ecosystem" program for grades 4 to 6: a real ecosystem model the whole class predicts and argues with on the projector, one improvement to the campus done for real, and a count before and after. No student accounts, no student data, no teacher prep beyond a sentence on the board. It maps to 5-LS2-1 and MS-LS2-4 and to California's environmental literacy blueprint.
>
> I'll be in San Diego the week of [date] and would value twelve minutes to run one lesson with you as the class. If it's useful, we'd pilot it free in two or three classrooms this spring and hand you the report.
>
> The program packet is attached, and the public version of our knowledge pages is at hopeling.app/swaps if you'd like to see how we cite things.
>
> Thank you,
> Yakir

One ask, one date, one attachment.

### The fifteen minutes

- **0 to 1.** "Nothing is learned until it is seen. We built the six weeks that get a class outside and bring it back with evidence."
- **1 to 3.** Their problem: science time is squeezed, environmental literacy is expected, materials assume a prep period that does not exist.
- **3 to 11.** The Bench, live. They are the class.
- **11 to 13.** Weeks five and six on one slide: the real improvement, the count, the report. Then the privacy sentence: no student accounts, no student data, here is the agreement.
- **13 to 15.** The ask: three classrooms, six weeks, free, starting [date]. You get the report. We get a reference.

No slide about the company. No slide about the consumer app. If they ask, it is the thing they can download tonight.

### The demo

The meadow, because it has a living diorama. Make the room predict the foxes. Most rooms get it wrong in the interesting direction. The moment a principal realises she guessed like a fourth grader and is delighted instead of embarrassed is the sale.

### What I bring

A Chromebook with the web build (not my phone), HDMI and USB-C adapters, ten printed packets, thirty one-pagers, the deck on a stick and in the cloud, a pre-filled CSDPA, a one-page pricing sheet, a one-page pilot agreement.

### From one yes to customers

One yes becomes a free six-week pilot in three classrooms with a start date. One visit during it (me or my co-founder) and the teacher gets a phone number. At the end, I write the report myself: one page, the before-and-after count, photographs, three student explanations verbatim. It goes to the principal, the county team and the institution partner, with permission, and becomes the case study on the schools page. The second school is sold with the first school's report. The county PD slot is earned with the second. The institution license is earned with the third.

---

## 5. Money

### The model, in priority order

1. **School program licensing.** The business for the next two years.
2. **Institutional partnerships.** The growth channel; pays per cohort of schools.
3. **Grants, through partners.** We are not eligible for most of them; our partners are. We make them fundable.
4. **Kids mode subscription.** Year three, after the brand exists.
5. **Consumer premium.** Probably never, or cosmetic only.
6. **Sponsored content.** No. The this-not-that pages are the reason anyone will trust us. A sponsor in that room ends our one advantage.

### What stays free

The consumer app, entirely. The public knowledge pages, forever. The Bench for any individual teacher who finds it (one class, no record, no packet). The free tier is the funnel and the proof.

### Pricing, as hypotheses to disprove

| Tier | What | My guess | What I compared it to |
|---|---|---|---|
| Teacher | The Bench, one class, no record | Free | Mystery Science's free tier |
| School | The full program, every teacher, class record, packet, report template | $1,500 to $2,500 per school per year | Generation Genius's school plan is about $1,000 to $1,300 a year ([NSTA](https://www.nsta.org/generation-genius)); a BrainPOP classroom license is $330 ([BrainPOP](https://www.brainpop.com/classroom-solutions/products/brainpop)) |
| District | Per student, minimum ten schools | $3 to $5 per student per year, floor $12,000 | Supplemental tools usually land in low single digits per student |
| Institution | Co-branded program for a cohort of partner schools | $15,000 to $40,000 per year per cohort of 10 to 25 schools | Funded from the institution's existing EE grants |

### Revenue scenarios (guesses, not forecasts)

- **Year one.** Five free pilots, three convert. Three schools at about $2,000: roughly $6,000. One institution pilot, unpaid. Revenue does not matter this year. The three reports are the asset.
- **Year two.** Thirty schools (ten direct, twenty through one institution cohort) plus a county PD relationship: around $85,000. Still not a salary for two.
- **Year three.** A hundred and fifty schools across three counties, three institution cohorts, one district: $400,000 to $600,000. That is when this is a company.

### What has to be true, in the order it gets tested

1. A teacher runs week one from the packet alone, without a call. (First pilot.)
2. A principal pays from site funds for a second year. (First renewal.)
3. An institution sees us as additive to its programs, not competitive. (First Birch conversation.)
4. Six-week completion is above 60 percent. (Below that, the program is too long.)
5. The class record is kept in year two. (If not, the moat is theoretical.)

Our acquisition cost in year one is my time: roughly twenty hours per school. That is the real number.

---

## 6. What to build next

### The five things, in order

1. **The web build for schools.** The Bench, the Lab, the Errand, the Long Record and the packet, on a Chromebook, from a link, with a class code. No student accounts. Everything else is behind this gate.
2. **The trust pack as a product.** A `/schools` page with the privacy policy, the data statement, the accessibility statement, the agreement templates, the security notes. Build it like a feature, because to a district it is one.
3. **The Long Record with class mode and a San Diego shelf.** Weeks three and six of the program do not exist without it, and it is the moat.
4. **The teacher's side, minimal.** Class code, record, printable packet, projection mode, the teacher's own box for the post-assessment.
5. **Pilot instrumentation that respects our rules.** Aggregate, anonymous, consented: lessons run, benches completed, signs logged, record kept. Plus a one-page case study template I fill in by hand.

### What to postpone

New Lab wings, Night Watch, the Year Book, the Grove of Knowing, more kids games, the guardian on the hill, the Hub, Circles, Wins. All good. None of them move a school.

### What makes the demo dramatically better

A real class record with two seasons of real data from a real pilot. One true dot beats anything invented. Then the kids film, thirty seconds, at the end, when the room is already won.

### What makes us look like a company and not a prototype

An entity. A support email that answers in a day. A status page. Versioned content with a changelog. Crash reporting. Offline reliability on a school network that blocks half the internet. An accessibility statement with a date. Terms of service. Insurance. A pricing page. A person's name and photo on the schools page. None of these is a feature. All of them are the difference between "impressive" and "we can sign this."

---

## 7. How people hear about us

Not social media. Teachers find tools from the teacher next door and at the one conference they attend.

- **The lesson plans are the ad.** Publish all twelve Bench lesson plans as free, beautiful PDFs on the schools page. A teacher downloads one, runs it with the free Bench, tells the teacher next door.
- **The Schoolyard Record as a public thing.** Every participating school's anonymous first signs on a map every spring: "first swallow by county." Journalists love phenology in spring. It is the one story about us that writes itself every year.
- **Three conferences, not thirty.** The California Science Education Conference, the AEOE conference, the Green California Schools Summit. Present the program, not the app. Bring the Bench.
- **Institutions as megaphones.** Every partner has a newsletter to its member schools. One co-branded announcement reaches more teachers than a year of posting.
- **Creators, carefully, later.** Birding and nature YouTubers who already use Merlin are the right adjacency for the consumer app. Not for the school motion.
- **Parents through children.** The Little Meadow and the kids film are the shareable objects. A parent who watches her seven-year-old repair a meadow sends the link. Make that link a page, not an App Store listing.
- **The story.** "Nothing is learned until it is seen." Or for the room: "every child is looking down at a screen; we built the thing that makes them look up." Same sentence everywhere, for two years.

---

## 8. The roadmap

### First 30 days: pilot-ready

- Form the entity. Bank account. Insurance quotes.
- Ship the web build of the School on a Chromebook; test it on a real school network.
- Write and publish the trust pack and the schools page. Have a lawyer read the privacy policy once.
- Localize: a San Diego sign shelf, a Pacific bird pack. My co-founder checks the birds.
- Secure one local pilot for the Long Record and the Bench where I live. Three classes. Start date on the calendar.
- Draft the ten introduction emails. Send the first three.

**Milestones:** web build live; trust pack public; one pilot scheduled; three emails sent.
**What will go wrong:** the web build will surface everything that assumed a phone. Two weeks, not one.

### First 90 days: proof and five meetings

- Run the local pilot. Visit twice. Collect the before-and-after count, photographs, three explanations.
- Write the one-page case study.
- Ship the Long Record with class mode and the pilot instrumentation.
- Send the remaining emails, each naming the last. Convert to five calendar invites.
- Book the trip only when there are five.

**Milestones:** one completed pilot with a report; the Long Record live; five confirmed meetings.
**What will go wrong:** the pilot teacher goes quiet in week four. A phone call, not an email.

### First 6 months: first revenue and a channel

- The San Diego trip. Five meetings, three pilots agreed, one institution conversation opened.
- Run the pilots remotely with one visit each.
- First paid licenses for the following school year, signed before July.
- A county PD slot or an institution cohort in discussion.
- A conference talk accepted.

**Milestones:** three San Diego pilots; two paid licenses; one institution term sheet or equivalent.
**What will go wrong:** the purchase cycle. Everything signs in spring for fall. If the trip is after April, the first paid year is a year away. The trip has to be February or March.

### First 12 months: a repeatable motion

- Ten to thirty schools, one institution cohort, one county relationship.
- The Schoolyard Record's first public spring map.
- The CSDPA signed by at least one district and in the registry.
- A decision, with data, on whether Kids mode becomes a subscription in year two.
- Enough revenue to pay one person part-time, or a clear reason to raise a small round.

**Milestones:** thirty schools or a signed cohort; one district agreement; renewal above 70 percent on the first pilots.
**What will go wrong:** me, doing everything. By month nine, one of sales or build has to be someone else.

### Who does what

- **Me:** the entity, the relationships, every meeting, every pilot visit or call, the case studies, the conference talk, pricing.
- **Us, building:** the web build, the trust-pack drafts, the Long Record, the teacher's side, the instrumentation, the localization, the packet revisions, the schools page, every follow-up document.
- **Outside help:** a lawyer for the privacy policy and the CSDPA (one afternoon), an accountant for the entity, an insurance broker, and by month nine a part-time educator-salesperson in California.

---

## 9. The things I do not want to hear, written down anyway

**San Diego is a good second market.** The first pilot should be wherever I can walk into a school this month. Proof travels; I do not need to. I should fly with a report in my bag, not a prototype.

**Schools are the right customer and the slowest one.** Annual cycles, no new money, a long objection list. Institutions are faster, mission-aligned, already funded, already in the classroom. The first paying customer may be an aquarium licensing the program for its partner schools, not a school. Court both. Expect the institution to sign first.

**Kids mode might be the bigger business and it is still the wrong first business.** Consumer kids apps have real revenue and brutal acquisition costs; the ones that win have free distribution. Schools are that distribution. Build the school motion so Kids mode launches with a thousand teachers sending a thousand parents.

**The product is too wide for a company.** In any school demo the Hub, adoption, pet care, Circles and Wins should not be visible. Not deleted. Not visible. A buyer who sees pet care in a science demo stops believing we are a science company.

**Our rules will cost us a sale, and we should let them.** Someone will ask for a leaderboard. A district will ask for per-student analytics. Say no in the room and write down who asked. The customers who stay because we said no are the ones who renew.

**The biggest opportunity may be the record, not the lesson.** Lessons are a crowded, cheap market. A ten-year schoolyard dataset kept by children, feeding national networks, with an institution's name on it, is a category with no incumbent. It is also the slowest thing to prove. Start now, because its value is a function of elapsed time, and nothing I do later can buy back the years.

**Two founders in two countries is a real constraint.** It is also why this can be a US company with a European-looking soul. My co-founder is the face in the room. I am the voice in the documents.

---

## 10. The bet, the checklist, the ten moves

### A. The bet

**The six-week program, sold through institutions, with the Long Record as the reason a school never leaves.** The lesson gets us in the door. The institution gets us to a hundred doors. The record is why nobody leaves. Everything else in the app is the free, beautiful reason people believe us when we knock.

### B. Before I fly

- [ ] An entity, a bank account, insurance quotes
- [ ] The School running on a Chromebook from a link, tested on a school network
- [ ] A San Diego sign shelf and a Pacific bird pack
- [ ] The Long Record with class mode, live
- [ ] The trust pack published: privacy policy, data statement, accessibility statement, security notes, terms, CSDPA ready to sign
- [ ] One completed pilot, anywhere, with a one-page report and a teacher who will take a call
- [ ] The packet, the deck, the one-pager, a three-minute film, a schools page with a pilot form, a pricing sheet, a one-page pilot agreement
- [ ] Ten introduction emails sent, each naming the last
- [ ] Five meetings on the calendar, at least two of them institutions
- [ ] The trip dated before April

### C. The next ten moves

1. Form the entity this week. Everything after this needs a name on a contract.
2. Start the web build. Nothing is sellable to an American school until it runs on a Chromebook.
3. Find the local pilot. A school I can reach by bus. Three classes, six weeks, a start date.
4. Build the Long Record with class mode, before anything else that is not on the trust list.
5. Publish the schools page and the trust pack. A district should be able to answer the privacy question without a meeting.
6. Localize for San Diego: the signs, the birds, two swap cards that matter there (lawn water; the car wash and the storm drain).
7. Send the first three emails: SDCOE environmental literacy, National School District, Birch Aquarium education. Each names the one before.
8. Run the local pilot and write the report myself. One page. Count, photographs, three explanations.
9. Turn the emails into five calendar invites. Then book the flight, and not before.
10. In the room: the Bench, the room as the class, the foxes, the ask for three classrooms. Leave the packet. Follow up the same evening with a one-page pilot agreement and a start date.

---

*Every price and revenue figure above is a guess to be tested. I will rewrite these notes after the first pilot report exists, because that report will be worth more than everything written here.*
