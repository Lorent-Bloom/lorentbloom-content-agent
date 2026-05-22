# Lorent Bloom — Brand Voice Reference

Human reference for the Lorent Bloom content agent. Examples, distribution
tables, and voice notes that complement the system prompt.

**The actual prompt sent to Groq lives in `brand-voice-system.md`** — that
file is read at runtime by the workflow's `Read brand voice` node. This
reference file is not loaded by the workflow.

If you change the brand voice, edit `brand-voice-system.md` to change the
runtime behavior; keep this file in sync only if the examples or rules of
thumb need updating for human readers.

---

## Topic perspective distribution

Posts rotate across three perspectives with a weighted distribution:

| Perspective | Weight | Monthly target (~30 posts) |
|---|---|---|
| Renter | 40% | ~12 posts |
| Owner | 40% | ~12 posts |
| Service | 20% | ~6 posts |

Implementation: the workflow's `Pick perspective` Code node rolls a
weighted random per run; `Switch by perspective` routes to the matching
perspective pool.

## Language rotation (per day, shuffled per week)

Posts rotate across ru / ro / en using a day-of-week schedule that is
itself re-shuffled every ISO week. The schedule is deterministic per week
— the same week always produces the same Mon→Sun pattern, but each new
week gets a fresh pattern (seeded by year × 100 + ISO week number).

Weekly distribution: **3 days ru, 2 days ro, 2 days en** (43% / 29% / 29%).

| Language | Weekly slots | Why |
|---|---|---|
| Russian (ru) | 3 | Largest audience in Moldova |
| Romanian (ro) | 2 | Romanian-speaking audience |
| English (en) | 2 | Expats, foreign visitors, international reach |

Implementation: `Pick language` seeds mulberry32 with the ISO week number,
shuffles `['ru','ru','ru','ro','ro','en','en']`, and indexes by current
day-of-week (Mon=0 … Sun=6).

## Voice examples (human reference; in-prompt examples are in `brand-voice-system.md`)

### Example 1 — Renter, listing spotlight (ru)

Кому-то в Кишинёве на этой неделе пригодится профессиональная камера Sony A7 IV — её сдают за 350 лей в день.

Это та самая камера, которую покупать смысла нет, если съёмка раз в год: выпускной, свадьба друга, большая поездка. А аренда на три дня обойдётся примерно в стоимость хорошего ужина на двоих.

С такой камерой за один уикенд можно отснять то, ради чего обычно нанимают фотографа. Объявление и фото — в каталоге Lorent Bloom. Цифровой договор и проверка владельца — стандартно, как в любой аренде у нас.

---

### Example 2 — Renter, money-saving calculation (ru)

Перфоратор средней мощности в магазине Кишинёва — около 3 500 лей. Используют его, в среднем, два раза: повесить полку в спальне и через год — карниз в гостиной.

В Lorent Bloom тот же перфоратор можно арендовать за 180 лей в день. То есть для тех двух задач — 360 лей вместо 3 500. Разница — 3 140 лей. Это месяц мобильного интернета, или ужин в хорошем ресторане, или почти весь набор школьной формы для ребёнка.

Покупают вещи на годы. Используют — на часы. Аренда возвращает разрыв в пользу кошелька.

---

### Example 3 — Owner, earning idea (ru)

Самые востребованные вещи в Lorent Bloom — это те, которые большинство людей покупают один раз и потом годами не трогают.

В Кишинёве чаще всего арендуют: дрели и перфораторы (после ремонта), палатки и спальники (раз в сезон), профессиональные камеры и объективы (свадьбы, путешествия), вечерние платья (одно мероприятие), детские самокаты и беговелы (когда ребёнок вырос).

Если хоть одна из этих вещей лежит у Вас дома и пылится — она уже сейчас может приносить от 150 до 400 лей в день. Загрузить объявление занимает минут пять. Первая аренда обычно случается на той же неделе.

---

### Example 4 — Service, trust (ru) [target voice, not yet generated]

Перед каждой арендой в Lorent Bloom оформляется цифровой договор — кто передаёт, кто получает, на какой срок, под какие условия. Подписи фиксируются в приложении, копия остаётся у обеих сторон.

Это не бюрократия ради бюрократии. Это то, что отличает аренду у соседа через Lorent Bloom от устной договорённости через знакомых. Если что-то идёт не так — есть к чему апеллировать.

Цифровой договор и проверка владельца через IDNP — стандарт каждой сделки. Без исключений.

---

### Example 5 — Romanian listing spotlight (ro) — for reference

Cineva din Chișinău are nevoie săptămâna aceasta de un aparat foto profesional Sony A7 IV — se închiriază pentru 350 lei pe zi.

Acesta este exact aparatul pe care nu are sens să-l cumpărați dacă filmați o dată pe an: o absolvire, nunta unui prieten, o călătorie importantă. Iar închirierea pentru trei zile costă cam cât o cină bună la restaurant pentru doi.

Anunțul și fotografiile sunt în catalogul Lorent Bloom. Contract digital și verificarea proprietarului — standard, ca la orice închiriere la noi.

> **Note:** Romanian text should be reviewed by a native speaker before
> shipping to production. The voice principles transfer cleanly, but
> nuance and idiom in Romanian deserve a human pass.

---

### Example 6 — English listing spotlight (en) — for reference

Someone in Chișinău is looking for a professional Sony A7 IV camera this
week — it rents for 350 lei a day.

This is exactly the camera you do not need to buy if you only shoot once a
year: a graduation, a friend's wedding, a long trip. Three days of rental
costs about the same as a good dinner for two.

The listing and photos are in the Lorent Bloom catalog. Digital contract
and owner verification through IDNP — standard on every rental, no
exceptions.

> **Note:** English text is included to reach expats and foreign visitors.
> Like Romanian, it should be reviewed by a fluent speaker before
> production use — the voice should feel formal-but-warm, not stiff.
