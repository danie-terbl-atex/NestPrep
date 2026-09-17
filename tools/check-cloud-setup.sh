#!/usr/bin/env bash
# What the cloud project still needs, and what it already has.
#
# Two steps in this project can only be taken by a person: linking a billing
# account, and starting Firebase Auth. Everything downstream of them is a
# command. This script says which of the two are done, does everything that is
# unblocked, and stops cleanly at the first thing it cannot do.
#
#   tools/check-cloud-setup.sh          report only
#   tools/check-cloud-setup.sh --apply  also deploy what is now deployable
#
# Safe to run repeatedly. Without --apply it changes nothing.

set -uo pipefail

PROJECT="nestprep-643b7"
APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

# gcloud is installed outside the default PATH on the machine this was written on.
[ -x "$HOME/google-cloud-sdk/bin/gcloud" ] && PATH="$HOME/google-cloud-sdk/bin:$PATH"

blocked=0
ok()      { printf '  \033[32mok\033[0m       %s\n' "$1"; }
missing() { printf '  \033[31mMISSING\033[0m  %s\n' "$1"; blocked=1; }
human()   { printf '  \033[33mYOU\033[0m      %s\n' "$1"; blocked=1; }
note()    { printf '           %s\n' "$1"; }

command -v gcloud   >/dev/null || { echo "gcloud is not on PATH"; exit 1; }
command -v firebase >/dev/null || { echo "firebase is not on PATH"; exit 1; }

echo
echo "NestPrep cloud project — $PROJECT"
echo

# ---------------------------------------------------------------- Firestore
if gcloud firestore databases list --project "$PROJECT" --format='value(name)' 2>/dev/null | grep -q .; then
  region=$(gcloud firestore databases list --project "$PROJECT" --format='value(locationId)' 2>/dev/null | head -1)
  ok "Firestore database exists (${region})"
else
  missing "no Firestore database — create it in africa-south1 (foundation ADR-0003)"
fi

# ------------------------------------------------------------------- rules
# A read nobody is signed in for must be refused. If it succeeds, the rules on
# the project are not the rules in this repo.
key=$(sed -n "s/.*apiKey: '\([^']*\)'.*/\1/p" app/lib/app/firebase_options.dart | head -1)
if [ -n "$key" ]; then
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 20 \
    "https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents/households?key=$key")
  case "$code" in
    403) ok  "security rules deployed and denying (403 to an unauthenticated read)" ;;
    200) missing "an unauthenticated read SUCCEEDED — the deployed rules are not this repo's" ;;
    *)   missing "unexpected $code from Firestore; cannot tell what the rules are" ;;
  esac
fi

# ------------------------------------------------------------------ billing
if [ "$(gcloud billing projects describe "$PROJECT" --format='value(billingEnabled)' 2>/dev/null)" = "True" ]; then
  ok "billing linked (Blaze) — Cloud Functions can deploy"
  billing=1
else
  human "link a billing account, or Cloud Functions can never deploy:"
  note  "gcloud billing accounts list"
  note  "gcloud billing projects link $PROJECT --billing-account=<ACCOUNT_ID>"
  note  "then add the budget alert at the R200 kill line (foundation ADR-0003)"
  billing=0
fi

# --------------------------------------------------------------------- auth
# A project whose Auth has never been started has no config at all, which is a
# step before enabling any provider.
token=$(gcloud auth print-access-token 2>/dev/null)
auth_config=$(curl -s -m 20 -H "Authorization: Bearer $token" -H "x-goog-user-project: $PROJECT" \
  "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT/config" 2>/dev/null)
if echo "$auth_config" | grep -q 'CONFIGURATION_NOT_FOUND'; then
  human "start Firebase Auth, then enable Google — console only, two steps:"
  note  "https://console.firebase.google.com/project/$PROJECT/authentication  →  Get started"
  note  "then Sign-in method → Google → enable. It mints the OAuth client that"
  note  "google-services.json needs and that no CLI can create."
  note  "afterwards: flutterfire configure --project=$PROJECT --platforms=android \\"
  note  "              --out=lib/app/firebase_options.dart   (run from app/)"
elif echo "$auth_config" | grep -q '"signIn"'; then
  if curl -s -m 20 -H "Authorization: Bearer $token" -H "x-goog-user-project: $PROJECT" \
      "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT/defaultSupportedIdpConfigs" \
      2>/dev/null | grep -q 'google.com'; then
    ok "Firebase Auth started and the Google provider is enabled"
  else
    human "Auth is started but the Google provider is not enabled (console → Sign-in method)"
  fi
else
  missing "could not read the Auth configuration; check that you are logged in to gcloud"
fi

# ------------------------------------------------------------ runtime APIs
enabled=$(gcloud services list --enabled --project "$PROJECT" --format='value(config.name)' 2>/dev/null)
for api in firestore identitytoolkit securetoken firebaseinstallations firebasecrashlytics cloudfunctions; do
  if echo "$enabled" | grep -qx "$api.googleapis.com"; then
    ok "API $api.googleapis.com"
  else
    missing "API $api.googleapis.com is not enabled"
    [ "$APPLY" = 1 ] && gcloud services enable "$api.googleapis.com" --project "$PROJECT" >/dev/null 2>&1 \
      && echo "           (enabled it just now)"
  fi
done

# ---------------------------------------------------------------- functions
echo
if [ "$billing" = 1 ]; then
  if [ "$APPLY" = 1 ]; then
    echo "Deploying Cloud Functions…"
    if firebase deploy --only functions --project "$PROJECT"; then
      ok "six callables deployed"
    else
      missing "the Functions deploy failed — read the output above"
    fi
  else
    note "billing is linked, so Cloud Functions are deployable:"
    note "  tools/check-cloud-setup.sh --apply    (or: firebase deploy --only functions)"
  fi
else
  note "Cloud Functions are not deployable until billing is linked. Once it is,"
  note "re-run this with --apply and it will deploy createHousehold, createInvite,"
  note "redeemInvite, leaveHousehold, removeMember and setMemberRole."
fi

echo
if [ "$blocked" = 0 ]; then
  echo "Everything this script can check is in place."
else
  echo "Lines marked YOU are the ones nothing here can do."
fi
exit 0
