---
layout: page
title: "Events"
permalink: /events/
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
padding:8px 14px;
border-radius:6px;
text-decoration:none;
font-size:13px;
font-weight:bold;
}

.section-title{
margin-top:40px;
font-size:22px;
color:#0f3d75;
}
</style>


# Events

This page highlights academic events I organize, co-organize, and participate in.


## Organizing

<div class="events-grid">

{% for event in site.events %}
{% if event.type == "Organizing" %}

<div class="event-card">

{% if event.image %}
<img src="{{ event.image }}" class="event-image">
{% endif %}

<div class="event-content">

<div class="event-title">
{{ event.title }}
</div>

<div class="event-meta">
{{ event.date | date: "%B %Y" }} • {{ event.location }}
</div>

<div class="event-desc">
{{ event.excerpt }}
</div>

<a href="{{ event.url }}" class="event-link">
View Event
</a>

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

{% if event.image %}
<img src="{{ event.image }}" class="event-image">
{% endif %}

<div class="event-content">

<div class="event-title">
{{ event.title }}
</div>

<div class="event-meta">
{{ event.date | date: "%B %Y" }} • {{ event.location }}
</div>

<div class="event-desc">
{{ event.excerpt }}
</div>

<a href="{{ event.url }}" class="event-link">
View Event
</a>

</div>
</div>

{% endif %}
{% endfor %}

</div>