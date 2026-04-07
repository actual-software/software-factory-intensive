# Review Policy

Standards applied by the Reviewer agent when evaluating code.

## Spec Compliance

- Every prop/input from the component spec must be implemented
- Every interaction from the spec must work as described
- Edge cases (empty, error, loading) must be handled
- Data types must match the spec exactly

## Style

- No inline styles — use Tailwind CSS classes
- Components under 200 lines (split if larger)
- No `any` types in TypeScript
- Consistent naming per project conventions

## Security

- No user input rendered without sanitization
- API endpoints validate all input parameters
- No secrets or credentials in code
- SQL queries use parameterized statements (no string concatenation)
- No `dangerouslySetInnerHTML` without explicit justification

## Testing

- Business logic functions must have unit tests
- Interactive components must have at least one user interaction test
- Tests must not depend on implementation details (test behavior, not structure)

## Severity Scale

- **Low**: style nit, minor improvement opportunity
- **Medium**: missing test, incomplete error handling, accessibility gap
- **High**: security issue, data corruption risk, spec violation
