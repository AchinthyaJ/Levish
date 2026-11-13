#!/usr/bin/env python3
"""Calendar data for Levish dashboard."""
import calendar
import json
from datetime import date

def get_calendar_data():
    today = date.today()
    cal = calendar.monthcalendar(today.year, today.month)
    month_name = today.strftime("%B")

    weeks = []
    for week in cal:
        row = []
        for day in week:
            row.append(day if day != 0 else None)
        weeks.append(row)

    return {
        "year": today.year,
        "month": month_name,
        "weeks": weeks,
        "today": today.day
    }

if __name__ == "__main__":
    print(json.dumps(get_calendar_data()))
