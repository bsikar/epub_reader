# Shared Services

This directory contains services that are shared across multiple features.

## Purpose
Services in this directory should:
- Be used by multiple features (not feature-specific)
- Provide cross-cutting concerns
- Be stateless or manage their own state independently

## Examples
- API clients
- Analytics services
- Notification services
- Platform-specific integrations
- Third-party service wrappers

## Note
For feature-specific services, place them in the respective feature's data layer.
For core infrastructure services (like storage), use `core/services/` instead.
