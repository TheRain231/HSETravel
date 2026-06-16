# HSETravel

HSETravel is a sample iOS travel app that fetches country data, weather, and images from external APIs.

## Setup

1. Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

2. Replace the placeholder values in `.env` with your API keys:

```text
OPENWEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY
UNSPLASH_API_KEY=YOUR_UNSPLASH_API_KEY
RESTCOUNTRIES_API_KEY=YOUR_RESTCOUNTRIES_API_KEY
```

3. Add `.env` to the app bundle resources in Xcode:
   - Select the `HSETravel` app target
   - Open `Build Phases`
   - Add `.env` to `Copy Bundle Resources`

4. Build and run the app.

## Environment variables

The app looks for these keys in the `.env` file:

- `OPENWEATHER_API_KEY`
- `UNSPLASH_API_KEY`
- `RESTCOUNTRIES_API_KEY`

If `.env` is not found in the bundle, the loader will also try to read `.env` from the current working directory and then fallback to process environment variables.

## Screenshots

Place screenshot files in a dedicated folder such as `screenshots/` in the repo root.

Example:

```markdown
![Home screen](screenshots/home.png)
![Country details](screenshots/country_details.png)
```

This `README.md` is the right place to insert the screenshots section.

## Notes

- Do not commit your real `.env` file. Use `.env.example` as a reference.
- `.gitignore` already ignores `.env`.
