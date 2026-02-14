---
name: brand-context
version: 1.0.0
description: "Create or update your brand positioning document. Use when you mention 'brand context,' 'positioning,' 'messaging,' 'who is this for,' or want consistent messaging across your marketing. Creates a reusable context file that other marketing skills reference automatically."
platform: cursor
category: marketing
---

# Brand Context for Education Entrepreneurs

You help education entrepreneurs create and maintain a brand positioning document. This captures your messaging foundations so every piece of marketing stays consistent, whether it's a newsletter, course sales page, LinkedIn post, or community welcome message.

The document is stored at `.claude/brand-context.md`.

## Why This Matters for Teachers-Turned-Entrepreneurs

Most teachers transitioning to business skip this step. They start writing copy, building courses, and posting on social media without a clear positioning foundation. The result: messaging that sounds different everywhere, confuses potential students, and undersells their expertise.

This skill fixes that. Once you have your brand context document, every other marketing task becomes faster and more consistent.

## Workflow

### Step 1: Check for Existing Context

First, check if `.claude/brand-context.md` already exists.

**If it exists:**
- Read it and summarise what's captured
- Ask which sections they want to update
- Only gather info for those sections

**If it doesn't exist, offer two options:**

1. **Auto-draft from existing materials** (recommended): Study the repo for README files, landing pages, course descriptions, about pages, social bios, and draft a V1. The user reviews and fills gaps. Much faster than starting blank.

2. **Start from scratch**: Walk through each section conversationally, one at a time.

Most users prefer option 1. After presenting the draft, ask: "What needs correcting? What's missing?"

### Step 2: Gather Information

**If auto-drafting:**
1. Read everything available: README, landing pages, course descriptions, about pages, social bios, any existing docs
2. Draft all sections based on what you find
3. Present the draft and ask what needs correcting
4. Iterate until accurate

**If starting from scratch:**
Walk through each section conversationally. Don't dump all questions at once.

**Critical rule:** Push for real language. Exact phrases your students and audience use are worth more than polished marketing speak. If they say "I'm stuck in a job that's killing me," capture that. Don't clean it up to "experiencing career dissatisfaction."

---

## Sections to Capture

### 1. Business Overview
- One-line description (what you do, who for)
- What your business actually does (2-3 sentences)
- Business category (what "shelf" do people find you on?)
- Business model (courses, coaching, community, SaaS, consulting, mix?)
- Pricing overview

### 2. Your Audience
- Who specifically do you serve? (job titles, career stage, demographics)
- What's their situation right now? (employed teacher, recently left, considering leaving, already transitioned?)
- Primary problem you solve for them
- Jobs to be done (2-3 things they "hire" you for)
- Specific scenarios where they find you

**For education businesses, dig into:**
- What subject/level did they teach?
- How many years in?
- What's their tech comfort level?
- Are they looking for side income or full career change?
- Do they have family/financial constraints?

### 3. Problems and Pain Points
- Core challenge they face before finding you
- Why current options fall short (free YouTube advice, generic career coaches, etc.)
- What it costs them to stay stuck (money, time, mental health, relationships)
- Emotional tension (what keeps them up at night?)

**Teacher-specific pain points to explore:**
- Burnout and compassion fatigue
- Feeling trapped by salary dependence
- Imposter syndrome about non-teaching skills
- Fear of "wasting" their degree/experience
- Guilt about leaving students
- Partner/family pressure about stability

### 4. Your Differentiators
- What makes you different from generic career coaches?
- What can you teach that others can't?
- What's your unique background or perspective?
- Why do people choose you over alternatives?

**Common differentiators for ex-teachers:**
- You've actually done the transition yourself
- You understand the specific psychology of leaving teaching
- You focus on skills teachers already have (not starting from zero)
- You serve a specific niche within education

### 5. Competitive Landscape
- **Direct competitors**: Others serving the same audience with similar offerings
- **Indirect competitors**: Generic career coaches, free resources, doing nothing
- **Alternative approaches**: Going back to study, applying for random jobs, staying and coping
- Where each falls short for your specific audience

### 6. Objections and Anti-Personas
- Top 3 objections you hear (cost, time, "but I'm just a teacher," etc.)
- How you address each one
- Who is NOT a good fit? (anti-persona)

### 7. Switching Dynamics (Four Forces)
- **Push**: What frustrations drive them away from their current situation?
- **Pull**: What attracts them to your solution?
- **Habit**: What keeps them stuck where they are?
- **Anxiety**: What worries them about making the change?

### 8. Student/Customer Language
- How they describe their problem (exact words from conversations, emails, comments)
- How they describe your solution after experiencing it
- Words and phrases to use in marketing
- Words and phrases to avoid

**Words teachers often use:**
- "Stuck," "trapped," "burning out," "invisible skills"
- "I don't know what else I can do"
- "I'm good at teaching but that's all I know"
- "I feel guilty for wanting to leave"

**Words to probably avoid:**
- "Hustle," "grind," "passive income" (feels exploitative)
- "Easy money," "get rich quick" (teachers are allergic to this)
- "Disrupt education" (they love education, they just need out of the system)

### 9. Brand Voice
- Tone (warm, direct, encouraging, no-nonsense?)
- Communication style (conversational, professional, mentor-like?)
- Brand personality (3-5 adjectives)
- Any specific language rules (Australian English? No jargon? No em dashes?)

### 10. Proof Points
- Key results or outcomes to cite
- Notable student stories
- Testimonial snippets
- Your own transition story (briefly)
- Media mentions, speaking, credentials

### 11. Goals
- Primary business goal right now
- Key conversion action (what do you want people to do first?)
- Revenue targets or growth metrics
- What does success look like in 12 months?

---

## Step 3: Create the Document

After gathering information, create `.claude/brand-context.md`:

```markdown
# Brand Context

*Last updated: [date]*

## Business Overview
**One-liner:**
**What we do:**
**Category:**
**Business model:**
**Pricing:**

## Our Audience
**Who they are:**
**Their situation:**
**Primary problem we solve:**
**Jobs to be done:**
-
**How they find us:**

## Problems and Pain Points
**Core challenge:**
**Why alternatives fall short:**
-
**What staying stuck costs them:**
**Emotional tension:**

## Differentiators
**What makes us different:**
-
**Why they choose us:**
**Our unique angle:**

## Competitive Landscape
**Direct:** [Competitor] — falls short because...
**Indirect:** [Alternative] — falls short because...
**Do nothing:** What happens if they stay...

## Objections
| Objection | Response |
|-----------|----------|
| | |

**Anti-persona (not for us):**

## Switching Dynamics
**Push (away from current):**
**Pull (toward us):**
**Habit (keeping them stuck):**
**Anxiety (about changing):**

## Student Language
**How they describe the problem:**
- "[exact words]"
**How they describe us after:**
- "[exact words]"
**Words to use:**
**Words to avoid:**

## Brand Voice
**Tone:**
**Style:**
**Personality:**
**Language rules:**

## Proof Points
**Results:**
**Student stories:**
**Testimonials:**
> "[quote]" — [who]
**Credentials:**

## Goals
**Primary goal:**
**Key conversion action:**
**Revenue target:**
**12-month vision:**
```

---

## Step 4: Confirm and Save

- Show the completed document
- Ask if anything needs adjustment
- Save to `.claude/brand-context.md`
- Tell them: "Other marketing skills will reference this automatically. Run this skill anytime to update it."

---

## Tips

- **Be specific**: "30-something primary school teachers in their 8th year who are crying in the car park" beats "career transitioners"
- **Capture real words**: Student language is marketing gold. Don't polish it.
- **Ask for stories**: "Tell me about a student who..." unlocks better answers than abstract questions
- **Skip what doesn't apply**: Solo coaches don't need enterprise personas
- **Update quarterly**: Your positioning evolves as your business grows
