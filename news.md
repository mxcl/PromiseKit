---
layout: default
title: News
nav: News
order: 4
---

# Announcements

<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
    </li>
  {% endfor %}
</ul>
