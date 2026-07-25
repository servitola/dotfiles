# The "So You Need A Typeface" decision tree

Julian Hansen's poster *So You Need A Typeface* (2010, a student project at the Danish School of
Media and Journalism), in the author's original English wording.

Two sources, cross-checked against each other: the poster itself (read here from the Russian
translation by xtotdam) and Ian Li's interactive recreation, which carries the tree as structured
data — [ianli.github.io/so-you-need-a-typeface](https://ianli.github.io/so-you-need-a-typeface/),
source in [github.com/ianli/so-you-need-a-typeface](https://github.com/ianli/so-you-need-a-typeface).
Where the two disagree, the recreation's routing wins: the poster is a graph with shared nodes and
crossing dotted lines, the recreation is the same content resolved into a tree.

The poster's own framing: *"An alternative way to choose a typeface (or just find inspiration) for
a project, without going through all the pages of FontBook. The list is (very loosely) based on 50
of the 100 Best Typefaces according to FontShop."* It resolves to 40 named faces.

**Start by choosing the kind of project you need the typeface for.**

## Contents

- [BOOK](#book)
- [NEWSPAPER](#newspaper)
- [INFOGRAPHIC](#infographic)
- [LOGO](#logo)
- [INVITATION](#invitation)
- [Where each face comes out](#where-each-face-comes-out)
- [Reading the poster instead](#reading-the-poster-instead)

## BOOK

```
Are you completely in doubt?
├─ Yes → Caslon                                  ("when in doubt, use Caslon")
└─ No  → A champion in usability perhaps?
         ├─ Yes → Minion
         └─ No  → Everybody loves Garamond
                  ├─ Yes → But perhaps one would want a larger eye?
                  │        ├─ Yes → Sabon
                  │        └─ No  → Garamond
                  └─ No  → So you want a sans serif, is that the case?
                           ├─ Yes → Optima
                           └─ No  → What is your opinion of Eric Gill?
                                    ├─ Good → Joanna
                                    └─ Bad  → Humanistic forms please your eye?
                                              ├─ Yes → Okay, to a question of food
                                              │        ├─ Gouda    → FF Scala
                                              │        └─ Emmental → Syntax
                                              └─ No  → Baskerville
```

## NEWSPAPER

Split by what the type does on the page: **text face**, **display**, or **combination**.

### Text face

```
Do people call you boring from time to time?
├─ Yes → Times
└─ No  → How about something heavily used?
         ├─ Yes → Miller
         └─ No  → How does relighting the American tradition sound?
                  ├─ Good → Proforma
                  └─ Bad  → Arnhem
```

### Display

```
Do you like it traditional?
├─ Yes → Do you like the type on highways?
│        ├─ Yes → Okay, to a question of age
│        │        ├─ New → Interstate
│        │        └─ Old → Franklin Gothic
│        └─ No  → It's okay with you if it's Swiss?
│                 └─ Yes → Helvetica
└─ No  → Something modern, yet plainspoken
         ├─ Yes → Gotham
         └─ No  → Not afraid to be asked if you lived in the nineties?
                  ├─ Yes → Helvetica
                  └─ No  → FF Meta
```

### Combination

```
Think Mr. Spiekermann is mostly right?
├─ Yes → Arnhem
└─ No  → The Netherlands is nice, right?
         ├─ Yes → Mmm. Spiky serifs are nice → OK → Swift
         └─ No  → Get out of my flowchart!   → Comic Sans
```

## INFOGRAPHIC

```
We all like something very condensed, yes?
├─ Yes → Univers
└─ No  → Got a lot of tables, have you?
         ├─ Yes → Letter Gothic
         └─ No  → You cried when watching Terminator
                  ├─ Yes → OCR
                  └─ No  → I must say that this flowchart is looking hot
                           └─ Yes → FF DIN
```

## LOGO

Two openings: **a sans serif maybe?** and **or perhaps a serif?**

### A sans serif maybe?

```
You like geometrics
├─ Yes → Do you like Futura?
│        ├─ Yes → Futura
│        └─ No  → Metro
└─ No  → A neo-grotesk perhaps?
         ├─ Yes → If I say "Science fiction movies are my favorite"
         │        ├─ Good → Eurostile
         │        └─ Bad  → Helvetica
         └─ No  → Something humanistic, then?
                  ├─ Yes → Do you like the look of Adobe?
                  │        ├─ Yes → Myriad
                  │        └─ No  → Frutiger
                  └─ No  → How about something classic?
                           ├─ Yes → Akzidenz Grotesk
                           └─ No  → Then we only have something decorative → OK → Peignot
```

### Or perhaps a serif?

```
How does the words semi-sans, semi-serif sound?
├─ Good → Rotis
└─ Bad  → Something new, got serifs, got sans?
          ├─ Good → Fedra
          └─ Bad  → Is it an Italian restaurant?
                    ├─ Yes → Bodoni
                    └─ No  → Got a whole bunch of office correspondence
                             ├─ Yes → Lexicon
                             └─ No  → Here we have a classic waiting for you → OK → Palatino
```

## INVITATION

```
Like something handwritten do you?
├─ Yes → Something calligraphic, maybe?
│        ├─ Yes → Zapfino
│        └─ No  → FF Erikrighthand
└─ No  → How about something a bit fancy?
         ├─ Yes → Thin hairlines     → Bodoni
         │        Thinner hairlines  → Readability?
         │                             ├─ Yes → Walbaum
         │                             └─ No  → Didot
         └─ No  → Something fun, then? Are you alone?
                  └─ Yes → Okay, then come with me → Comic Sans
```

## Where each face comes out

All 40 endpoints:

| Face | Lands from |
|---|---|
| Akzidenz Grotesk | logo · sans · not humanistic · "how about something classic?" yes |
| Arnhem | newspaper · text · American tradition sounds bad — or combination · Spiekermann is right |
| Baskerville | book · not a sans · Gill is bad · humanistic forms do not please the eye |
| Bodoni | logo · serif · Italian restaurant — or invitation · fancy · thin hairlines |
| Caslon | book · completely in doubt |
| Comic Sans | newspaper · "get out of my flowchart!" — or invitation · fun · alone |
| Didot | invitation · fancy · thinner hairlines · readability no |
| Eurostile | logo · neo-grotesk · sci-fi line lands well |
| Fedra | logo · serif · something new with serifs and sans |
| FF DIN | infographic · "this flowchart is looking hot" |
| FF Erikrighthand | invitation · handwritten · not calligraphic |
| FF Meta | newspaper · display · afraid of the nineties question |
| FF Scala | book · humanistic forms · Gouda |
| Franklin Gothic | newspaper · display · highways · old |
| Frutiger | logo · humanistic · does not like the Adobe look |
| Futura | logo · geometrics · likes Futura |
| Garamond | book · loves Garamond · no larger eye needed |
| Gotham | newspaper · display · modern yet plainspoken |
| Helvetica | newspaper · display · Swiss is fine / not afraid of the nineties — or logo · neo-grotesk · sci-fi line lands badly |
| Interstate | newspaper · display · highways · new |
| Joanna | book · not a sans · Gill is good |
| Letter Gothic | infographic · a lot of tables |
| Lexicon | logo · serif · a whole bunch of office correspondence |
| Metro | logo · geometrics · does not like Futura |
| Miller | newspaper · text · something heavily used |
| Minion | book · a champion in usability |
| Myriad | logo · humanistic · likes the Adobe look |
| OCR | infographic · cried watching Terminator |
| Optima | book · wants a sans serif |
| Palatino | logo · serif · "here we have a classic waiting for you" |
| Peignot | logo · "then we only have something decorative" |
| Proforma | newspaper · text · relighting the American tradition sounds good |
| Rotis | logo · serif · semi-sans semi-serif sounds good |
| Sabon | book · loves Garamond · wants a larger eye |
| Swift | newspaper · combination · the Netherlands · spiky serifs |
| Syntax | book · humanistic forms · Emmental |
| Times | newspaper · text · called boring from time to time |
| Univers | infographic · likes something very condensed |
| Walbaum | invitation · fancy · thinner hairlines · readability yes |
| Zapfino | invitation · handwritten · calligraphic |

## Reading the poster instead

The printed poster is a maze, not a tree, and differs from the data above in three ways worth
knowing when someone shows you the image:

- **Shared nodes.** "Okay, to a question of age" and the highways question sit between the
  newspaper display branch and the logo sans branch, so several routes converge on Helvetica and
  Franklin Gothic.
- **The sci-fi question** is drawn near Interstate and wires its bad answer toward FF Meta on the
  poster; the recreation places it under the logo neo-grotesk branch with Helvetica as the bad
  answer.
- **"Get out of my flowchart!"** is a dead end in the recreation; on the poster the line continues
  down to Comic Sans, which is the joke.
