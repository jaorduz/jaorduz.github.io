---
layout: archive
title: "Publications and other derivated contributions"
permalink: /publications/
author_profile: true
---

<!--#### [Up](#PDFCVInfoJO)-->
<!-- #### [home](../) -->

{% if author.googlescholar %}
  <!-- You can also find my articles on 
  <u><a href="{{author.googlescholar}}">
  my Google Scholar profile
  </a>.</u> -->
{% endif %}

{% include base_path %}

{% for post in site.publications reversed %}
  {% include archive-single.html %}
{% endfor %}

<!-- #### [home](../) -->