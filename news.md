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
      <a href="{{ post.url }}">{{ post.title }}</a>
    </li>
  {% endfor %}
</ul>

# Changelog

[Visit Changelog on GitHub](https://github.com/mxcl/PromiseKit/blob/master/CHANGELOG.markdown).