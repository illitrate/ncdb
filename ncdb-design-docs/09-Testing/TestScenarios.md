# NCDB Test Scenarios

## Overview

This document outlines specific test scenarios for the Nicolas Cage Database app, organized by feature area.

---

## 1. Movie Browsing

### Scenario 1.1: View Movie List
| Property | Value |
|----------|-------|
| Type | UI Test |
| Priority | High |

**Steps:**
1. Open Movies tab
2. Observe movie list

**Expected:** Movies display with posters, titles sorted by release date

### Scenario 1.2: Search Movies
**Steps:**
1. Tap search bar
2. Type "Face"
3. Observe results

**Expected:** Results filter as user types, "Face/Off" appears

### Scenario 1.3: Filter by Decade
**Steps:**
1. Tap filter button
2. Select "1990s"

**Expected:** Only 1990s movies shown, filter indicator visible

---

## 2. Movie Details

### Scenario 2.1: View Movie Details
**Steps:**
1. Tap on "Con Air"
2. Scroll through details

**Expected:** Title, year, runtime, overview, cast displayed

### Scenario 2.2: Mark Movie as Watched
**Steps:**
1. Tap "Mark as Watched" button

**Expected:** Button changes, date set, achievement check runs

### Scenario 2.3: Rate Movie
**Steps:**
1. Tap rating stars
2. Select 4.5 stars

**Expected:** Rating persists, haptic feedback

---

## 3. Ranking System

### Scenario 3.1: Add Movie to Rankings
**Steps:**
1. Long-press watched movie
2. Select "Add to Rankings"

**Expected:** Movie appears in ranking list

### Scenario 3.2: Reorder Rankings
**Steps:**
1. Long-press #3 movie
2. Drag to #1 position

**Expected:** Items reorder with animation, persists

---

## 4. Achievements

### Scenario 4.1: Unlock First Movie Achievement
**Steps:**
1. Mark first movie as watched

**Expected:** "First Steps" achievement unlocks with celebration

### Scenario 4.2: View Achievement Progress
**Steps:**
1. Open Profile > Achievements
2. View locked achievement

**Expected:** Progress bar visible, requirements listed

---

## 5. Sync & Data

### Scenario 5.1: iCloud Sync
**Steps:**
1. Mark movie watched on Device A
2. Check Device B

**Expected:** Movie syncs across devices

### Scenario 5.2: Offline Mode
**Steps:**
1. Enable airplane mode
2. Browse and mark movie watched
3. Disable airplane mode

**Expected:** Cached data available, syncs on reconnect

---

## 6. Accessibility

### Scenario 6.1: VoiceOver Navigation
**Steps:**
1. Navigate through movie list with VoiceOver
2. Open movie detail

**Expected:** All elements announced with meaningful labels

### Scenario 6.2: Dynamic Type
**Steps:**
1. Set largest text size
2. Browse app

**Expected:** Text scales, layout adapts

---

## 7. Performance

### Scenario 7.1: App Launch Time
**Expected:** < 2 seconds to first frame

### Scenario 7.2: List Scrolling
**Expected:** 60 FPS maintained during rapid scroll

### Scenario 7.3: Memory Usage
**Expected:** < 200 MB baseline, < 400 MB peak

---

## Regression Checklist

Before each release:
- [ ] Onboarding completes
- [ ] Movie list loads
- [ ] Search works
- [ ] Watch marking persists
- [ ] Ratings save
- [ ] Rankings reorder
- [ ] Achievements unlock
- [ ] iCloud sync works
- [ ] Widgets update
- [ ] VoiceOver works
- [ ] No crashes
