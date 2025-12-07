# News Scraper System

## Overview

The News Scraper system automatically fetches Nicolas Cage-related articles from multiple RSS feeds and web sources, filtering and prioritizing them based on relevance.

## Supported News Sources

### RSS-Based Sources
1. **Google News** (Priority 1)
   - Aggregates from multiple sources
   - URL: `https://news.google.com/rss/search?q=Nicolas+Cage`
   
2. **Variety** (Priority 2)
   - Trade publication covering Hollywood
   - URL: `https://variety.com/feed/`

3. **The Hollywood Reporter** (Priority 3)
   - Entertainment industry news
   - URL: `https://www.hollywoodreporter.com/feed/`

4. **Deadline** (Priority 4)
   - Breaking entertainment news
   - URL: `https://deadline.com/feed/`

5. **Collider** (Priority 5)
   - Entertainment news and reviews
   - URL: `https://collider.com/feed/`

### Non-RSS Sources (Future Implementation)
6. **IMDb News** (Priority 6)
   - Requires web scraping
   
7. **TMDb News** (Priority 7)
   - Requires API integration

## Filtering Strategy

Articles are filtered using the following keywords:
- "nicolas cage"
- "nicolas kim coppola" (birth name)
- "nick cage"
- "nic cage"

Only articles containing at least one keyword in the title or summary are stored.

## Relevance Scoring Algorithm

Each article receives a relevance score (0.0-1.0) based on:

| Criteria | Score Weight |
|----------|--------------|
| "Nicolas Cage" in title | +0.5 |
| "Nicolas Cage" in summary | +0.3 |
| Category: New Movie/Casting | +0.2 |
| Category: Interview/Award | +0.15 |
| Category: Review/Box Office | +0.1 |
| Published within 7 days | +0.1 |

## Article Categories

- **New Movie Announcement** - Upcoming projects
- **Casting News** - Role announcements
- **Interview** - Q&A sessions, profiles
- **Review** - Film/performance reviews
- **Box Office** - Financial performance
- **Award News** - Nominations, wins
- **Personal Life** - Non-professional news
- **General News** - Miscellaneous

## Storage Management

- **Maximum per source**: 20 articles per scrape
- **Total storage limit**: 200 articles
- **Pruning**: Oldest articles deleted when limit exceeded
- **Duplicate prevention**: URL uniqueness constraint

## Scraping Frequency Options

Users can configure automatic refresh:
- **Manual Only** - User-initiated only
- **Once Daily** - Every 24 hours
- **Twice Daily** - Every 12 hours
- **Once Weekly** - Every 7 days

## Background Refresh

When enabled:
- Uses iOS Background Tasks framework
- Identifier: `com.yourapp.ncdb.newsrefresh`
- Runs during optimal device conditions
- User can disable in Settings

## User Features

### Reading & Organization
- **Read/Unread tracking** - Mark articles as read
- **Favorites** - Save important articles
- **Notes** - Add personal comments

### Viewing Options
- **Horizontal scroll** on Home view (5 most recent unread)
- **Full list view** with search and filtering
- **Filter by source** - View articles from specific outlets
- **Filter by read status** - Show only unread

### Display Priority
Articles displayed in order of:
1. Relevance score (descending)
2. Published date (newest first)

## Error Handling

Graceful fallback when:
- Network unavailable (uses cached articles)
- Feed parsing fails (continues with other sources)
- Rate limits hit (shows last successful scrape date)

## Dependencies

**FeedKit** - RSS/Atom feed parsing
```swift
.package(url: "https://github.com/nmdias/FeedKit.git", from: "9.1.2")
```

## Future Enhancements

1. **Full article scraping** - Store complete article text
2. **IMDb integration** - Web scraping or API
3. **TMDb integration** - Use their news API if available
4. **Push notifications** - Alert for major news
5. **Article summarization** - AI-generated summaries
6. **Social sharing** - Share articles to social media
7. **Reading time estimates** - Display article length
8. **Offline reading mode** - Cache full article content
