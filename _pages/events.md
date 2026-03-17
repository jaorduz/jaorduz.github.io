---
layout: single
title: "Events"
permalink: /events/
author_profile: true
---

<style>
.events-grid{
  display:grid;
  grid-template-columns:repeat(auto-fit,minmax(320px,1fr));
  gap:24px;
  margin-top:20px;
}

.event-card{
  background:white;
  border-radius:12px;
  box-shadow:0 6px 20px rgba(0,0,0,.08);
  overflow:hidden;
  transition:transform .2s;
}

.event-card:hover{
  transform:translateY(-5px);
}

.event-image{
  width:100%;
  height:180px;
  object-fit:cover;
}

.event-content{
  padding:18px;
}

.event-title{
  font-size:18px;
  font-weight:bold;
  color:#0f3d75;
  margin-bottom:8px;
}

.event-title a{
  color:#0f3d75;
  text-decoration:none;
}

.event-meta{
  font-size:13px;
  color:#666;
  margin-bottom:10px;
}

.event-desc{
  font-size:14px;
  line-height:1.5;
  margin-bottom:12px;
}

.event-link{
  display:inline-block;
  background:#0f3d75;
  color:white;
  padding:10px 16px;
  border-radius:8px;
  text-decoration:none;
  font-size:14px;
  font-weight:600;
}

.section-title{
  margin-top:40px;
  font-size:22px;
  color:#0f3d75;
}
</style>

## Organizing

<div class="events-grid">
{% for event in site.events %}
  {% if event.type == "Organizing" %}
    <div class="event-card">

      {% if event.image %}
      <img src="{{ event.image }}" class="event-image" alt="{{ event.title }}">
      {% endif %}

      <div class="event-content">
        <div class="event-title">
          <a href="{{ event.external_url | default: event.url }}" target="_blank" rel="noopener noreferrer">
            {{ event.title }}
          </a>
        </div>

        <div class="event-meta">
          {{ event.date | date: "%B %Y" }} • {{ event.location }}
        </div>

        <div class="event-desc">
          {{ event.excerpt }}
        </div>

        <p><strong>Venue:</strong> {{ event.venue }}</p>

        <a href="{{ event.external_url | default: event.url }}" class="event-link" target="_blank" rel="noopener noreferrer">
          {{ event.cta_label | default: "Visit RAB 2026 Website" }}
        </a>

        <!-- <p style="margin-top:10px;">
          <a href="{{ event.url }}">View internal archive page</a>
        </p>
         -->
      </div>
    </div>
  {% endif %}
{% endfor %}
</div>

## Participating

<div class="events-grid">
{% for event in site.events %}
  {% if event.type == "Participating" %}
    <div class="event-card">
      <div class="event-content">
        <div class="event-title">
          <a href="{{ event.external_url | default: event.url }}" target="_blank" rel="noopener noreferrer">
            {{ event.title }}
          </a>
        </div>

        <div class="event-meta">
          {{ event.date | date: "%B %Y" }} • {{ event.location }}
        </div>

        <div class="event-desc">
          {{ event.excerpt }}
        </div>

        <a href="{{ event.external_url | default: event.url }}" class="event-link" target="_blank" rel="noopener noreferrer">
          {{ event.cta_label | default: "View Event" }}
        </a>

        <!-- <p style="margin-top:10px;">
          <a href="{{ event.url }}">View internal archive page</a>
        </p> -->

      </div>
    </div>
  {% endif %}
{% endfor %}
</div>

## Past Events

<div class="events-grid">
{% for event in site.events %}
  {% if event.type == "Past" %}
    <div class="event-card">
      <div class="event-content">
        <div class="event-title">
          <a href="{{ event.external_url | default: event.url }}" target="_blank" rel="noopener noreferrer">
            {{ event.title }}
          </a>
        </div>

        <div class="event-meta">
          {{ event.date | date: "%B %Y" }} • {{ event.location }}
        </div>

        <div class="event-desc">
          {{ event.excerpt }}
        </div>

        <a href="{{ event.external_url | default: event.url }}" class="event-link" target="_blank" rel="noopener noreferrer">
          {{ event.cta_label | default: "View Event" }}
        </a>

        <!-- <p style="margin-top:10px;">
          <a href="{{ event.url }}">View internal archive page</a>
        </p>
         -->
      </div>
    </div>
  {% endif %}
{% endfor %}
</div>