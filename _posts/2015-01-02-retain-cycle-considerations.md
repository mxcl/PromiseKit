---
category: docs
layout: default
---

<h1>Retain Cycle Considerations</h1>

tl;dr: it’s safe to use self in promise handlers.

Provided all your promises resolve, the handlers will be released, and any retain cycles caused by referencing `self` in your promise handlers will be dereferenced.

The exception would be if you store the promise handler as a strong property on your class, but that would be a strange thing to do. Don’t do that.

<div><a class="pagination" href="/promises-make-better-apps">Next: Promises Make Better Apps</a></div>
