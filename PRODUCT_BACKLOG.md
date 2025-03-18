# DSR-Scripts Product Backlog

This document outlines planned enhancements and features for the DSR-Scripts developer toolbox.

## High Priority

### Database Schema Integration
- [ ] Add schema-based database initialization for Vite+React+Prisma projects
- [ ] Support input of schema file or interactive schema definition
- [ ] Generate initial Prisma schema and migrations based on input
- [ ] Add sample data seeding functionality
- [ ] Implement TypeScript type generation from schema

### Deployment Configuration
- [ ] Implement deployment options for multiple platforms:
  - [ ] Vercel deployment configuration and scripts
  - [ ] Netlify deployment configuration and scripts
  - [ ] Render deployment configuration
  - [ ] Railway deployment integration
  - [ ] Fly.io configuration and deployment scripts
  - [ ] Azure resource group deployment via Bicep templates
  - [ ] Supabase backend integration options

## Medium Priority

### Project Template Enhancements
- [ ] Add TypeScript support to all Node.js templates
- [ ] Implement Docker containerization options
- [ ] Add testing framework integration (Jest, Vitest, pytest)
- [ ] Create CI/CD GitHub Actions workflow templates
- [ ] Improve monorepo support (NX, Turborepo options)
- [ ] Add React UI template options (SaaS, brochure site)
  - [ ] Material UI integration options
  - [ ] Pre-built component libraries
  - [ ] Responsive layouts and navigation

### Content-Driven Project Creation
- [ ] Support for Markdown-based project configuration:
  - [ ] `schema.md` - Define database structure in plain language
  - [ ] `layout.md` - Describe site structure and page components
  - [ ] `copy.md` - Define site content (headings, text, CTAs)
- [ ] Provide templates for each configuration file type
- [ ] Generate complete projects from Markdown specifications

### Developer Experience
- [ ] Add interactive CLI with project configuration wizard
- [ ] Implement project scaffolding via configuration files
- [ ] Create visual documentation with example outputs
- [ ] Add command for adding new features to existing projects

## Future Considerations

### Framework Support
- [ ] Add Next.js template
- [ ] Add SvelteKit template
- [ ] Add FastAPI Python template
- [ ] Support for additional languages (Go, Rust)

### Advanced Features
- [ ] Environment management across multiple deployment targets
- [ ] Cost estimation tool for different deployment options
- [ ] Integration with infrastructure as code (Terraform, Pulumi)
- [ ] Automatic database migration strategies
- [ ] Multi-environment configuration management