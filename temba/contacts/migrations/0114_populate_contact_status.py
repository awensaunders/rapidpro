# Generated by Django 2.2.10 on 2020-08-20 15:27

from django.db import migrations

STATUS_ACTIVE = "A"
STATUS_BLOCKED = "B"
STATUS_STOPPED = "S"


def populate_contact_status(apps, schema_editor):  # pragma: no cover
    Contact = apps.get_model("contacts", "Contact")
    contacts = Contact.objects.values("id", "status", "is_stopped", "is_blocked")

    num_contacts = 0
    max_id = -1
    while True:
        batch = list(contacts.filter(id__gt=max_id).order_by("id")[:5000])
        if not batch:
            break

        active_ids = []
        blocked_ids = []
        stopped_ids = []

        for contact in batch:
            if contact["status"]:
                continue
            elif contact["is_stopped"]:
                stopped_ids.append(contact["id"])
            elif contact["is_blocked"]:
                blocked_ids.append(contact["id"])
            else:
                active_ids.append(contact["id"])

        if active_ids:
            Contact.objects.filter(id__in=active_ids).update(status=STATUS_ACTIVE)
        if blocked_ids:
            Contact.objects.filter(id__in=blocked_ids).update(status=STATUS_BLOCKED)
        if stopped_ids:
            Contact.objects.filter(id__in=stopped_ids).update(status=STATUS_STOPPED)

        num_contacts += len(batch)
        print(
            f"   - Updated {num_contacts} contacts "
            f"(active={len(active_ids)}, blocked={len(blocked_ids)}, stopped={len(stopped_ids)})"
        )

        max_id = batch[-1]["id"]


def reverse(apps, schema_editor):  # pragma: no cover
    pass


def apply_manual():  # pragma: no cover
    from django.apps import apps

    populate_contact_status(apps, None)


class Migration(migrations.Migration):

    dependencies = [
        ("contacts", "0113_contact_status"),
    ]

    operations = [migrations.RunPython(populate_contact_status, reverse)]
