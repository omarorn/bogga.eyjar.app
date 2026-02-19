# Video Tutorial Scripts

**Created:** January 6, 2026
**Purpose:** Comprehensive scripts for generating AI-powered video tutorials

---

## Overview

This directory contains detailed scripts for 5 professional video tutorials to help users learn the Litla Gámaleigan system.

**Total Duration:** 13 minutes
**Language:** Icelandic (with English subtitles)
**Format:** MP4, 1080p, H.264

---

## Video Inventory

| Tutorial | Duration | Audience | File |
|----------|----------|----------|------|
| Container Management | 3 min | Admin | `admin-container-management.txt` |
| Order Management | 2 min | Admin | `admin-order-management.txt` |
| GPS Navigation | 3 min | Driver | `driver-gps-navigation.txt` |
| Completing Pickups | 2 min | Driver | `driver-completing-pickups.txt` |
| Customer Portal Guide | 3 min | Customer | `customer-portal-guide.txt` |

---

## Script Structure

Each script follows this format:

### 1. Metadata
- Duration
- Language (Icelandic + English subtitles)
- Avatar recommendation

### 2. Content Sections
- **Opening** (0:00-0:15) - Introduction
- **Main Sections** - Step-by-step walkthrough with timestamps
- **Closing** (end) - Summary and contact info
- **Key Takeaways** - Summary slide with bullet points

### 3. Production Notes
- Avatar settings (voice, appearance, background)
- Screen recording requirements
- Export settings (format, resolution, bitrate)
- Music and subtitle specifications

---

## Usage

### Step 1: Choose AI Video Tool

**Recommended:** Synthesia (https://www.synthesia.io)
- Best quality
- Icelandic language support
- Professional avatars
- $29-89/month

**Alternatives:**
- D-ID (https://www.d-id.com) - $5.90-196/month
- HeyGen (https://www.heygen.com) - $29-89/month

### Step 2: Generate Videos

1. Sign up for AI video tool
2. Create new video project
3. Upload script from this directory
4. Select Icelandic avatar and voice
5. Add screen recordings or placeholder slides
6. Generate video (5-10 minutes)
7. Download MP4 (1080p)

### Step 3: Upload to R2

```bash
# Run upload script
bash scripts/upload-tutorial-videos.sh

# Or manually upload
wrangler r2 object put litla-gamaleigan-images/videos/tutorials/admin-container-management.mp4 \
  --file=assets/video-tutorials/admin-container-management.mp4 \
  --content-type="video/mp4"
```

### Step 4: Verify Deployment

Videos are automatically embedded in:
- **Admin Dashboard:** `/admin/help` (Help.tsx)
- **Driver App:** `/driver/help` (Help.tsx)
- **Customer Portal:** `/portal/hjalp` (hjalp.astro)

---

## Video URLs (Production)

Once uploaded to R2, videos are accessible at:

```
https://pub-f803b94d3cea4783afd4aa1f0dde6e56.r2.dev/videos/tutorials/admin-container-management.mp4
https://pub-f803b94d3cea4783afd4aa1f0dde6e56.r2.dev/videos/tutorials/admin-order-management.mp4
https://pub-f803b94d3cea4783afd4aa1f0dde6e56.r2.dev/videos/tutorials/driver-gps-navigation.mp4
https://pub-f803b94d3cea4783afd4aa1f0dde6e56.r2.dev/videos/tutorials/driver-completing-pickups.mp4
https://pub-f803b94d3cea4783afd4aa1f0dde6e56.r2.dev/videos/tutorials/customer-portal-guide.mp4
```

---

## Script Highlights

### Admin - Container Management (3 min)

**Key Topics:**
- Login and dashboard navigation
- Viewing container list with filters
- Creating new containers
- Editing container details
- Real-time sensor data
- Setting alert thresholds
- Assigning containers to customers

**Screen Recordings Needed:**
- Login flow
- Container list page
- Create container form
- Container detail modal
- Real-time fill level updates

---

### Admin - Order Management (2 min)

**Key Topics:**
- Navigate to Orders page
- Create new order (customer + container selection)
- Assign to driver and route
- Track order status progression
- View completion photos and notes
- Generate and send invoice

**Screen Recordings Needed:**
- Orders list page
- Create order flow
- Order assignment modal
- Order status tracking
- Invoice generation

---

### Driver - GPS Navigation (3 min)

**Key Topics:**
- View today's route with all stops
- Start navigation to next stop
- Follow turn-by-turn directions
- Handle rerouting if missed turn
- Arrive at destination
- Mark stop as complete

**Screen Recordings Needed:**
- Route overview (mobile)
- GPS map with turn-by-turn
- Rerouting notification
- Arrival screen
- Stop completion

---

### Driver - Completing Pickups (2 min)

**Key Topics:**
- Arrive at location
- Take before photo (full container)
- Empty container
- Take after photo (empty container)
- Note any issues (damaged lid, wrong location)
- Mark pickup as complete
- Move to next stop

**Screen Recordings Needed:**
- Stop detail screen (mobile)
- Camera interface for photos
- Notes/issues form
- Completion confirmation

---

### Customer - Portal Guide (3 min)

**Key Topics:**
- Login to customer portal
- Dashboard overview with container stats
- View container fill levels (real-time)
- Check pickup history with photos
- Request a collection (date + priority)
- View and pay invoices
- Contact support

**Screen Recordings Needed:**
- Portal login
- Dashboard overview
- Container detail page
- Request collection form
- Invoice list and payment

---

## Avatar Recommendations

### Admin Tutorials
- **Avatar:** Professional Icelandic (Dóra or similar)
- **Age:** 30-40 years old
- **Attire:** Business casual
- **Background:** Office setting
- **Tone:** Professional, helpful

### Driver Tutorials
- **Avatar:** Casual, friendly (Gunnar or similar)
- **Age:** 25-35 years old
- **Attire:** Work uniform or casual
- **Background:** Outdoor/field setting
- **Tone:** Friendly, instructive

### Customer Tutorial
- **Avatar:** Friendly, approachable (Dóra or similar)
- **Age:** 30-40 years old
- **Attire:** Business casual
- **Background:** Office or café setting
- **Tone:** Warm, customer-service oriented

---

## Icelandic Voice Settings

**Synthesia Voices:**
- **Dóra** (Female) - Professional, clear, friendly
- **Gunnar** (Male) - Warm, approachable, helpful

**Voice Parameters:**
- **Language:** Icelandic (is-IS)
- **Speed:** 1.0x (normal)
- **Pitch:** Default
- **Emphasis:** Standard

---

## Screen Recording Tips

### Resolution
- **Desktop:** 1920x1080 (Full HD)
- **Mobile:** 1080x1920 (Portrait)

### Recording Tools
- **Windows:** OBS Studio (free) or Camtasia
- **Mac:** QuickTime or ScreenFlow
- **Web:** Loom or CloudApp

### Best Practices
- Show cursor movements
- Highlight clicked elements (circle animation)
- Use smooth panning and zooming
- Pause 2-3 seconds on each screen
- Avoid rapid scrolling
- Keep UI text readable (>14px font)

---

## Export Settings

### Video Format
- **Format:** MP4
- **Codec:** H.264
- **Resolution:** 1920x1080 (landscape) or 1080x1920 (portrait)
- **Bitrate:** 5 Mbps (desktop) or 4 Mbps (mobile)
- **Frame Rate:** 30 fps

### Audio Format
- **Codec:** AAC
- **Bitrate:** 128 kbps
- **Channels:** Stereo (2.0)
- **Sample Rate:** 48 kHz

### Subtitles
- **Primary:** Icelandic (hardcoded)
- **Secondary:** English (SRT file optional)
- **Font:** Arial, size 32, white with black outline
- **Position:** Bottom center

---

## File Naming Convention

**Videos:**
- `admin-container-management.mp4`
- `admin-order-management.mp4`
- `driver-gps-navigation.mp4`
- `driver-completing-pickups.mp4`
- `customer-portal-guide.mp4`

**Thumbnails:**
- `admin-container-management-thumbnail.jpg`
- `admin-order-management-thumbnail.jpg`
- `driver-gps-navigation-thumbnail.jpg`
- `driver-completing-pickups-thumbnail.jpg`
- `customer-portal-guide-thumbnail.jpg`

---

## Next Steps

1. **Generate Videos:**
   - Sign up for Synthesia or alternative
   - Upload scripts from this directory
   - Generate all 5 videos

2. **Create Thumbnails:**
   - Extract frame at 10 seconds (FFmpeg)
   - Or design custom thumbnail (Canva/Figma)

3. **Upload to R2:**
   - Run `bash scripts/upload-tutorial-videos.sh`
   - Verify uploads with `wrangler r2 object list`

4. **Test Embedding:**
   - Admin: https://admin.gamaleigan.is/help
   - Driver: https://okumenn.gamaleigan.is/help
   - Customer: https://www.gamaleigan.is/portal/hjalp

5. **Gather Feedback:**
   - Share with test users
   - Iterate on scripts if needed
   - Re-generate improved versions

---

## Maintenance

### Updating Videos

If you need to update a video:

1. Edit script in this directory
2. Re-generate video with AI tool
3. Re-upload to R2 (same filename overwrites)
4. Clear CDN cache if needed
5. Test in production

### Adding New Tutorials

To add a new tutorial:

1. Create script: `scripts/video-tutorials/new-tutorial.txt`
2. Follow existing script structure
3. Generate video
4. Upload to R2: `videos/tutorials/new-tutorial.mp4`
5. Add to Help page component
6. Update this README

---

## Resources

**AI Video Tools:**
- Synthesia: https://www.synthesia.io
- D-ID: https://www.d-id.com
- HeyGen: https://www.heygen.com

**Documentation:**
- Full guide: `docs/VIDEO_TUTORIAL_GUIDE.md`
- Upload script: `scripts/upload-tutorial-videos.sh`
- Help pages:
  - Admin: `apps/litla-admin/src/pages/Help.tsx`
  - Driver: `apps/litla-drivers/src/pages/Help.tsx`
  - Customer: `apps/litlagamaleigan-web/src/pages/portal/hjalp.astro`

---

**Prepared by:** Ómar Örn Magnússon (Vertis.is)
**Date:** January 6, 2026
**Project:** Litla Gámaleigan - Smart Waste Container Management
