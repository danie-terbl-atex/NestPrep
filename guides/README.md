# nestprep guides

How-to guides for every main feature of nestprep, the app and the nestprep Home frame. Each folder holds one guide, and its README lists the steps it walks through. We'll use these later to script and capture the guide videos.

A guide shows one journey from start to finish, on the device the viewer would hold. Where another person's view matters (a nanny, a helper, a child, the frame on the wall), the guide shows their screen too. That way a parent knows exactly what the other person will see.

## Guides

| Section | Guides |
|---|---|
| [01 Getting started](01-getting-started/) | sign-up-main-parent · welcome-tour · account-and-privacy |
| [02 Family and people](02-family-and-people/) | add-a-child · invite-co-parent-or-family · add-a-nanny-or-carer · add-a-helper · roles-and-what-each-person-sees · manage-your-household · two-homes |
| [03 Lunch](03-lunch/) | plan-lunch-week-yourself · plan-lunch-with-twig · did-they-eat-it · lunch-tools · kid-picks-their-lunch |
| [04 Meals and groceries](04-meals-and-groceries/) | recipes-and-meal-plan · grocery-list · link-your-shops · fill-your-shop-cart · compare-shops · snap-a-shopping-list |
| [05 Calendar and to-dos](05-calendar-and-todos/) | family-calendar · connect-calendars-and-school-letters · todos-and-routines · chores-stars-and-rewards |
| [06 Nanny hub](06-nanny-hub/) | set-up-the-nanny-hub · the-carers-shift · pickups-and-shift-only-access |
| [07 Home care](07-home-care/) | set-up-cleaning-jobs · the-helpers-day · room-routines-and-stock |
| [08 Documents](08-documents/) | documents-and-the-vault |
| [09 Today, alerts and location](09-today-alerts-and-location/) | today-and-the-morning-digest · notifications · where-we-are |
| [10 nestprep Home frame](10-nestprep-home-frame/) | buy-a-frame-and-claim-premium · set-up-and-link-the-frame · the-frame-day-to-day · using-the-frame-by-touch · cook-along-on-the-frame · a-helpers-day-on-the-frame · manage-your-frames |
| [11 Premium](11-premium/) | premium-free-vs-paid · referrals-and-premium-codes |
| [12 Assistants](12-assistants/) | connect-claude-or-chatgpt |

## Before filming any guide

- **The bottom bar** is Today · Calendar · Food · Lists · More. Food switches between Lunch and Meals, and Lists switches between To do and Groceries.
- **Feature switches** are on unless `appConfig/flags` sets them to `false`. Check the live values before filming. Each guide names the switches it needs.
- **Premium:** a guide marked Premium needs a Premium household. Any guide with two or more children needs one too, because the free plan covers one child.
- **Roles in the app:** Admin, Parent, Child, Helper, and Nanny or carer. There is no "adult" role, and a grandparent joins as a Parent.
- **Capture real screens:** use the demo household (the Naidoo-Botha family) on the emulator backend or the demo logins. Never film the real household's data.
- **Status notes:** each README ends with *Not live yet / check first* where part of the journey isn't proven on a device.

## Labels to fix before we film

The app says one thing and the button says another in these places. Fix the copy first, or script the real button.

- The kid pairing sheet says "I have a code from a grown-up"; the button is **I have a code**.
- The invite web page says "I have an invite code"; the sign-in button is **I have a code**.
- The kid code screen says "go to Household"; the route is More → People → Manage people.

## Each guide README

- **Who it's for:** the viewer.
- **Devices on screen:** whose phone, a kid's tablet, the frame.
- **Before filming:** Premium, switches, the data that must exist.
- **Steps:** the journey in order, using the real UI labels.
- **What they see:** the other person's screen, where it matters.
- **Not live yet / check first.**
