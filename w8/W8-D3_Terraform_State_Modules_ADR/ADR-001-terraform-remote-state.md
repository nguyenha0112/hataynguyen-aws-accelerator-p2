# ADR-001: Use S3 Remote State With DynamoDB Locking

Date: 2026-06-03

## Status

Proposed

## Context

Terraform needs state to map configuration to real infrastructure. Local state is simple for solo practice but risky in a team because it can be lost, overwritten, or applied from different machines without coordination.

## Decision

Use an S3 bucket for remote Terraform state and a DynamoDB table for state locking. Enable encryption for the state bucket.

## Consequences

- Team members can share the same state location.
- DynamoDB locking reduces the risk of concurrent applies.
- S3 versioning can help recover previous state versions.
- Access control must be configured carefully because state may contain sensitive values.

## Mentor Questions

1. How should we separate state between dev, staging, and production?
2. Should each team member have a personal sandbox state path?
3. What minimum IAM permissions should Terraform have for this lab?

