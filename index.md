---
layout: default
---
<h1>Mandarin HSK Study Site</h1>
<p class="lead">Welcome!  Learn Mandarin Chinese with our HSK-focused lessons and graded readings.</p>

<div class="row">
    <div class="col-md-6">
        <h2>Lessons</h2>
        <ul>
          {% for lesson in site.lessons %}
            <li><a href="{{ site.url }}{{ site.baseurl }}/{{ lesson.url }}">{{ lesson.title }}</a></li>
          {% endfor %}
        </ul>
    </div>
    <div class="col-md-6">
        <h2>Readings</h2>
        <ul>
          {% for story in site.readings %}
            <li><a href="{{ site.url }}{{ site.baseurl }}/{{ story.url }}">{{ story.title }}</a></li>
          {% endfor %}
        </ul>
    </div>
</div>

<h2>Coming Soon!</h2>
<ul>
    <li>Use Your Own Text</li>
    <li>Accelerated Reader (for quick Hanzi memorization)</li>
    <li>Downloadable Flashcard files for Pleco</li>
    <li>In browser flashcards</li>
</ul>

<h2>Known Issues</h2>
<p> File new issues on github at <a href="https://github.com/shadowcodex/hanzi-website/issues">github.com/shadowcodex/hanzi-website</a>
<ul>
    <li>Not all definitions are showing up.  Need to generate larger definition files.</li>
    <li>Grammar sections need improvement.</li>
</ul>

<p>Built with 💖 by <a href="https://github.com/shadowcodex">shadowcodex</a></p>
