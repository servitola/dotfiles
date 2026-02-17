---
name: dashboard-builder
description: Builds interactive dashboards with React, Next.js, shadcn/ui, Tailwind CSS, and Recharts. Use for data visualization needs.
---

# Dashboard Builder Skill

Creates modern, responsive dashboards with beautiful visualizations for ${project_name}.

## Tech Stack

- **Framework**: Next.js 14+ (App Router)
- **UI**: shadcn/ui components
- **Styling**: Tailwind CSS
- **Charts**: Recharts / Chart.js
- **State**: Zustand / React Query
- **Theme**: Dark mode support

## Dashboard Types

### Analytics Dashboard
- Traffic metrics
- User engagement
- Conversion funnels
- Real-time data

### Admin Dashboard
- User management
- Content moderation
- System health
- Activity logs

### Data Visualization
- Time series charts
- Comparison charts
- Geographic maps
- Heat maps

## Component Library

### Charts
- Line charts (trends over time)
- Bar charts (comparisons)
- Pie/Donut charts (distributions)
- Area charts (cumulative data)
- Scatter plots (correlations)
- Heat maps (density)

### Widgets
- Stat cards (KPIs)
- Data tables (sortable, paginated)
- Activity feeds
- Progress indicators
- Alerts and notifications

## Process

### 1. Requirements Gathering
- What metrics to display?
- What's the data source?
- Who is the audience?
- What actions should users take?

### 2. Design Layout
- Grid system and responsive breakpoints
- Component hierarchy
- Color scheme and theme
- Dark mode considerations

### 3. Implementation
```bash
npx create-next-app@latest dashboard
cd dashboard
npx shadcn-ui@latest init
npx shadcn-ui@latest add card table chart
npm install recharts zustand
```

### 4. Data Integration
- API endpoints
- Real-time updates (WebSocket/SSE)
- Caching strategy
- Error handling

## Best Practices

- **Performance**: Lazy loading, virtualization for large datasets
- **Accessibility**: ARIA labels, keyboard navigation
- **Responsive**: Mobile-first design
- **Theme**: Consistent color palette, dark mode
- **Loading**: Skeleton screens, loading states

## Example Structure

```
dashboard/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   └── dashboard/
│       ├── overview/
│       ├── analytics/
│       └── settings/
├── components/
│   ├── charts/
│   ├── widgets/
│   └── layout/
├── lib/
│   ├── api.ts
│   └── utils.ts
└── hooks/
    └── use-data.ts
```
