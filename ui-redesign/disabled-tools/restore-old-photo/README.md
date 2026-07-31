# Restore old photo (disabled)

Tool eliminat din Home Screen. Poate fi reactivat oricând.

## Cum reactivezi

1. Creează înapoi imagesets:
   - `AI Image Generator/Assets.xcassets/tool_restore_photo_before.imageset/`
   - `AI Image Generator/Assets.xcassets/tool_restore_photo_after.imageset/`
   - Fiecare cu `before.png` / `after.png` de aici + un `Contents.json` (vezi
     structura la celelalte tool_*.imageset)
2. Decomentează blocul `ToolExample` din `AI Image Generator/Views/HomeView.swift`
   (marcat `// DISABLED: Restore old photo`)

## In-app prompt

```
restore this old damaged photo
```

## Prompturi Gemini pentru regenerare

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
