# Home Screen — Tool Demo Prompts

Prompturi Gemini (Nano Banana / Imagen) pentru generarea imaginilor Before/After
afișate în cardurile de pe Home (`AI Image Generator/Views/HomeView.swift` →
`ToolExample.defaults`).

Aici sunt salvate DOAR prompturile pentru tool-urile care au deja imaginile
puse în app. Restul se adaugă când sunt gata.

## Reguli generale

Aplică în TOATE prompturile pentru consistență:

- `1:1 square aspect ratio`
- `No text, no labels, no watermarks, no borders`
- La AFTER: **urcă imaginea Before ca reference image** în Gemini și adaugă
  `keep the exact same person from the reference image, only change X`
- Copy-paste identic descrierea subiectului (păr, față, îmbrăcăminte, poză)
  în ambele prompturi — schimbă doar partea care face diferența
- După generare: dacă apare watermark „Gemini" în colț, curățar-l manual sau
  folosește un tool de crop / inpaint

---

## 1. Change background (10 credits)

**In-app prompt:** `replace the background with a scenic tropical beach at sunset`

**Assets:** `tool_change_bg_before.imageset`, `tool_change_bg_after.imageset`

### BEFORE

```
A confident young woman with long wavy chestnut hair, warm sun-kissed skin,
wearing a vibrant red bikini, standing with right hand on hip, gentle smile.
Medium shot mid-thigh up. Background: crowded busy beach — messy towels,
umbrellas, other tourists, beach bags cluttered on the sand, lifeguard tower
in the distance. Bright midday natural lighting. Fashion editorial.
1:1 square. No text, no watermarks.
```

### AFTER

```
The exact same woman, exact same red bikini, identical pose and hairstyle.
Background now a breathtaking tropical paradise at golden hour — turquoise
ocean, palm trees, warm orange-pink sunset sky, cinematic depth of field.
Subject naturally lit to match sunset — golden skin tones, subtle rim light
on hair. Fashion editorial magazine quality. 1:1 square. No text, no watermarks.
```

---

## 2. Beautify (5 credits)

**In-app prompt:** `beautify the person in this photo with natural skin retouching,
brighter eyes and a healthy glow — keep it realistic, not overly filtered`

**Assets:** `tool_beautify_before.imageset`, `tool_beautify_after.imageset`

### BEFORE

```
Close-up portrait of a young woman in her mid-twenties with long straight
brown hair pulled back, medium shot chest up, neutral expression looking at
camera. Visible imperfections: small blemishes and acne spots on cheeks and
chin, uneven skin tone with slight redness, dark circles and puffiness under
eyes, dry patches on forehead, chapped natural lips, tired dull complexion.
Simple white t-shirt. Plain soft grey studio background, flat unflattering
overhead lighting. Photorealistic natural photography.
1:1 square. No text, no watermarks.
```

### AFTER

```
The exact same young woman, exact same hair pulled back, identical pose, same
neutral expression, same white t-shirt. BEAUTIFIED with subtle natural
retouching — smooth clear skin, no blemishes, even balanced tone with healthy
glow, no dark circles, bright well-rested eyes, softer plump lips with subtle
rosy tint, flawless complexion, natural cheek blush, subtle highlight on
cheekbones. Still realistic — NOT plastic, NOT overly filtered, NOT airbrushed
to fake. Same grey background but soft flattering beauty lighting with warm
rim light. Magazine beauty photography. Photorealistic.
1:1 square. No text, no watermarks.
```

---

## 3. Restore old photo (10 credits) — **DISABLED**

> ⚠ Tool eliminat din Home. Assets + prompturi mutate la
> `ui-redesign/disabled-tools/restore-old-photo/` (vezi README acolo).

**In-app prompt:** `restore this old damaged photo`

**Assets:** _mutate în_ `ui-redesign/disabled-tools/restore-old-photo/`

### BEFORE

```
A vintage 1940s black and white family portrait in a formal studio setting.
A family of five posed together: an older grandfather with a moustache seated
in a wooden chair on the left, a grandmother in a floral dress seated next
to him on the right, their adult son standing behind wearing a suit, his wife
standing next to him in an elegant dress with pearl necklace, and their young
daughter around 8 years old standing in front of the seated grandparents
wearing a knee-length dress with a bow. All facing camera with gentle formal
smiles, classic studio pose. The photograph is BADLY DAMAGED: yellowed sepia
tones, deep vertical scratches across the entire image, torn corners with
pieces missing, water stains discoloring parts of the faces and clothing,
dust spots, faded washed-out areas, deep creases and fold marks running
through the image, blurry from age, cracks and small tears, dried adhesive
residue in corners suggesting it was ripped from an old photo album. Old
family photo found in an attic. Photorealistic period-accurate 1940s
photography. 1:1 square aspect ratio. No text, no labels, no watermarks.
```

### AFTER

```
The exact same family of five in the exact same studio composition:
grandfather with moustache seated left, grandmother in floral dress seated
right, adult son standing behind in a suit, his wife next to him in an
elegant dress with pearl necklace, young daughter around 8 years old
standing in front of the grandparents in her knee-length dress with a bow.
Identical poses, identical formal gentle smiles, identical camera framing
and studio composition. Now PERFECTLY RESTORED and COLORIZED: crisp sharp
focus, all damage completely removed (no scratches, no tears, no stains, no
fold marks, no missing pieces), natural realistic vibrant colors added
everywhere — warm natural skin tones on all faces, blue and brown eyes,
grandmother's floral dress with soft pink and green tones, son's charcoal
grey suit, wife's navy blue dress with genuine white pearls, daughter's mint
green dress with a red bow, warm brown wooden chair, soft cream studio
backdrop, gentle warm studio lighting. Looks like a modern high-resolution
family portrait. Professional photo restoration and colorization.
1:1 square aspect ratio. No text, no labels, no watermarks.
```

---

## 4. Change outfit (10 credits) — red dress

**In-app prompt:** `change the outfit of the person in this photo to a different
stylish clothing while keeping the same pose and identity`

**Assets:** `tool_change_outfit_before.imageset`, `tool_change_outfit_after.imageset`

### BEFORE (framing full body head-to-feet obligatoriu)

```
A confident young woman with shoulder-length wavy blonde hair, natural
makeup, gentle smile. STRICT FULL BODY SHOT — camera 3 meters away, entire
body visible from head to feet including shoes, feet clearly on the ground,
no body part cropped. Feet slightly apart, hands relaxed at sides. Wearing
a plain oversized grey hoodie, simple black leggings, black flat shoes.
Neutral warm beige studio backdrop, soft even front lighting. Wide vertical
composition with generous space above head and below feet. Photorealistic
fashion catalog photography. 1:1 square. No text, no watermarks.
```

### AFTER (urcă BEFORE ca reference image!)

```
Using the exact same woman from the reference image — keep her face, hair,
identity, pose, body proportions and camera framing 100% IDENTICAL. Same
distance, same crop, same feet position, same hands at sides. Only CHANGE
HER OUTFIT to a STUNNING BLOOD-RED FLOOR-LENGTH EVENING DRESS in deep
crimson silk satin. Intricate details: hand-embroidered floral patterns in
matching red thread along the bodice, subtle red sequins catching light,
fitted corset top with sweetheart neckline, long fitted sleeves in sheer
red lace, flowing A-line skirt reaching the floor covering her feet,
delicate crystal beading around the waist. Same neutral beige studio
backdrop, same soft lighting, same shadow direction. Vogue magazine
quality. Photorealistic. 1:1 square. No text, no watermarks.
```

---

## 5. Erase an object (10 credits) — wedding cars

**In-app prompt:** `erase the distracting objects from this photo, seamlessly
reconstruct the background`

**Assets:** `tool_erase_object_before.imageset`, `tool_erase_object_after.imageset`

### BEFORE

```
A gorgeous newlywed bride in a flowing white lace wedding dress and long
veil, holding hands with her groom in a black tuxedo, both facing camera
with radiant happy smiles, standing on lush green grass in a beautiful
countryside estate with rolling hills in the background at golden hour.
Behind them in the frame are UGLY DISTRACTING elements: three parked
cars (a silver SUV, a red sedan, a black minivan) blocking part of the
scenic hills, ruining the romantic wedding moment. Wide cinematic wedding
photography. 1:1 square. No text, no watermarks.
```

### AFTER (urcă BEFORE ca reference image)

```
Using the exact same wedding scene from the reference image — same bride
in white lace dress, same groom in tuxedo, identical poses and radiant
smiles, same countryside setting, same golden hour lighting. The ONLY
change: ALL THREE CARS are COMPLETELY REMOVED, replaced seamlessly with
matching rolling green hills, wildflowers and trees, natural extension of
the landscape. Picture-perfect fairytale wedding scene. Wide cinematic
wedding photography. 1:1 square. No text, no watermarks.
```

---

## 6. Glow up (10 credits) — couple lifestyle upgrade

**In-app prompt:** `give the people in this photo an ultimate luxury lifestyle
glow up — elegant outfits, expensive jewelry and watches, upscale background,
keep their identities`

**Assets:** `tool_glow_up_before.imageset`, `tool_glow_up_after.imageset`

### BEFORE (couple, ordinary outdoor middle-class)

```
A young couple in their late twenties standing side by side outside on an
ordinary suburban driveway of a small modest single-story house. She has
natural undone hair loosely tied back, minimal or no makeup, wearing a
simple oversized grey knit cardigan over a plain white t-shirt and casual
light-wash mom jeans, comfortable white sneakers. He has slightly messy
hair, a bit of stubble, wearing a plain navy t-shirt, faded blue jeans,
and worn canvas sneakers. Both looking at camera with gentle easygoing
smiles, standing close together with his arm loosely around her shoulder.
Setting: an ordinary older compact family car parked behind them on the
driveway (a modest silver Toyota Corolla, average condition, nothing
fancy). Behind the car, a plain suburban house with white vinyl siding,
an average front lawn with a basic garden hose lying on it, cloudy
overcast afternoon light, no drama, dull grey sky. Ordinary weekend
everyday snapshot, flat unflattering natural lighting, slightly washed-out
realistic colors. Middle-class relatable ordinary lifestyle — not poor,
just basic and unremarkable. Full body shot, camera 3 meters away, feet
visible on the driveway pavement. 1:1 square. No text, no watermarks.
```

### AFTER (urcă BEFORE ca reference image — ultimate luxury glow up)

```
Using the exact same young couple from the reference image — keep their
faces, identities, and same standing pose side by side, his arm loosely
around her shoulder, both looking directly at camera with radiant
confident smiles. Same full body framing, camera 3 meters away, feet
clearly visible on the ground. ULTIMATE GLOW UP TRANSFORMATION to elite
luxury lifestyle.

SHE now wears: a stunning floor-length champagne silk evening gown with
intricate crystal embroidery along the bodice, long sparkling diamond
earrings, sleek glossy hair styled in soft waves, flawless professional
makeup with bold red lipstick, a large gold Cartier Panthère bracelet
watch clearly visible on her left wrist, delicate diamond rings on her
fingers.

HE now wears: a perfectly tailored midnight black Tom Ford tuxedo with
satin lapels, crisp white dress shirt, black silk bow tie, freshly styled
hair, clean sharp shave, and a LARGE ICONIC GOLD ROLEX DAYTONA watch
prominently displayed on his left wrist.

Setting completely transformed into paralleling luxury version: they
stand on a POLISHED WHITE MARBLE DRIVEWAY. Directly behind them: TWO
STUNNING LUXURY CARS parked side by side — a matte BLACK LAMBORGHINI
URUS on one side and a WHITE ROLLS-ROYCE PHANTOM on the other, both
fully visible with glossy polished paint reflecting warm light. Behind
the cars: a magnificent Mediterranean-style MANSION with tall arched
windows, white marble columns, manicured palm trees and lush green
gardens, dramatic warm GOLDEN HOUR SUNSET SKY with soft orange and
pink clouds, cinematic warm lighting bathing the entire scene.

Vogue magazine editorial photography, high-end fashion, dreamy
aspirational millionaire lifestyle, magazine cover quality. Full body
shot, camera 3 meters away, feet clearly visible on the marble driveway
in identical framing to the reference. 1:1 square. No text, no watermarks.
```

---

## Convenția de naming pentru assets

- `Assets.xcassets/tool_<slug>_before.imageset/before.png`
- `Assets.xcassets/tool_<slug>_after.imageset/after.png`

Contents.json pentru fiecare imageset:

```json
{
  "images": [
    { "filename": "before.png", "idiom": "universal", "scale": "1x" },
    { "idiom": "universal", "scale": "2x" },
    { "idiom": "universal", "scale": "3x" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

Referirea în cod: `ToolExample(..., beforeImage: "tool_<slug>_before",
afterImage: "tool_<slug>_after")` în `HomeView.swift`.
