# Initialization — first-time site setup

Run once per topic. Flow:

1. Ask **two** quick questions (no more — keep it light):
   - What should the site be called (this goes in the header)?
   - What is the main thing first — blog, portfolio, photos, or just a
     personal page? This guides where to start; sections can be added
     later anytime.
2. Run the initializer:
   ```
   bash ~/projects/dotfiles/claude-code/skills/create-regular-website/scripts/init-topic.sh "$PWD"
   ```
3. Edit `site.yaml`: set `name` to what the user chose. If the user
   speaks Russian by default, set `lang: ru`; for English `lang: en`.
   Other languages — see [style-language.md](style-language.md).
4. Confirm to the user in their language, *without listing files or
   folders*. Something like: "Done, you now have a site called X. Send
   me photos, texts, ideas — I will sort them. Say 'publish' when you
   want it live."

## Topic layout (what gets scaffolded)

The template the AI copies into a new site topic lives at
`~/projects/dotfiles/claude-code/skills/create-regular-website/topic-template/`.
After init the user's topic looks like:

```
site.yaml          - settings (name, colors, sections)
links.yaml         - socials
home.md            - hero text on the front page
about.md           - about page
posts/             - blog posts
images/            - shared images
projects/          - portfolio entries
gallery/           - photo albums
engine/            - Astro build code (do not touch)
built-site/        - last built output (gitignored)
README.md          - tiny how-to for the user
```
