# Landing Page Redesign Plan

The goal is to transform the current basic landing page into a professional, modern, and attractive entry point for LexiCoach. The redesign will focus on visual hierarchy, consistent branding, and improved user flow.

## User Review Required

> [!IMPORTANT]
> The redesign will adopt the color palette used in the `SignUpPage` (`#6547E8` primary) to ensure brand consistency across the app.

## Proposed Changes

### UI & UX Enhancement

#### [MODIFY] [landing.dart](file:///C:/Users/eyana/StudioProjects/lexicoach/lib/landing.dart)
- **Background:** Replace the plain white background with a subtle gradient or a light tinted background (`#F9F7FF`) to match the sign-up flow.
- **Header:** Refine the "LexiCoach" branding with better spacing and a more modern font weight.
- **Hero Section:** Replace the grey circle placeholder with a more sophisticated visual element (e.g., a stylized icon or an image-like container with a gradient).
- **Typography:** Implement a clear hierarchy:
  - Headline: Bold, dark navy (`#222033`).
  - Sub-headline: Medium weight, muted purple/grey (`#77718A`).
- **Call to Action (CTA):**
  - Style the "Get Started" button to be more prominent using the primary purple (`#6547E8`).
  - Link "Get Started" to the `SignUpPage`.
  - Style the "Log In" button as a clean outlined button.
- **Footer:** Add a subtle "Why LexiCoach" or tag line at the bottom with improved styling.

## Verification Plan

### Manual Verification
- Verify the layout on different screen sizes (using the device emulator).
- Ensure the "Get Started" button correctly navigates to the `SignUpPage`.
- Ensure the "Log In" button correctly navigates to the `SignInPage`.
- Confirm the color scheme matches the `SignUpPage`.
