---
layout: page
title: "Events"
permalink: /events/
---

# Events

## Organizing

{% for event in site.events %}
  {% if event.type == "One day event" %}

### {{ event.title }}

{{ event.excerpt }}

- **Date:** {{ event.date | date: "%B %Y" }}
- **Venue:** {{ event.venue }}
- **Location:** {{ event.location }}
- **Website:** [Visit event]({{ event.permalink }})

  {% endif %}
{% endfor %}