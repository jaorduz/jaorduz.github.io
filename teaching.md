---
layout: default
title: Teaching
permalink: /teaching/
---

{% for item in site.teaching %}
  <h2><a href="{{ item.url | relative_url }}">{{ item.title }}</a></h2>
  <p>{{ item.date | date: "%B %Y" }}</p>
  <p>{{ item.venue }}</p>
  <p>{{ item.excerpt }}</p>
  <hr>
{% endfor %}