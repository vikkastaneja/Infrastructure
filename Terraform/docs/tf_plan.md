## Reading and Interpreting `terraform plan` Output

When you run `terraform plan`, Terraform outputs a "diff" representing what it intends to change in the real world to make it match your code. 

### 1. The Action Symbols
Terraform uses symbols next to each resource to tell you exactly what is going to happen:
*   `+` (Green): Create a new resource.
*   `-` (Red): Destroy an existing resource.
*   `~` (Yellow): Update/modify an existing resource in-place.
*   `-/+` (Red/Green): Destroy and recreate. (This happens when you change an immutable attribute, like an EC2 instance type, forcing Terraform to kill the old one and build a new one).

### 2. Identifying "(known after apply)"
You will often see fields explicitly marked as `(known after apply)`:
```text
  + resource "aws_vpc" "this" {
      + arn        = (known after apply)
      + cidr_block = "10.0.0.0/16"
      + id         = (known after apply)
    }
```
**Why this happens:** Terraform knows you want the CIDR block to be `10.0.0.0/16` because you explicitly hardcoded it in `main.tf`. However, it cannot possibly know what the physical AWS ID (e.g., `vpc-01234abcd5678`) or the ARN will be until AWS actually creates it. This is normal and expected behavior.

### 3. The Final Summary Line
Always check the very bottom of the output for the summary line:
> `Plan: 25 to add, 0 to change, 0 to destroy.`

*   **To Add:** Should jump up drastically on your first run. If you run the plan a second time without changing code, it should be `0 to add`.
*   **To Destroy:** **ALWAYS check this number.** If someone accidentally deletes a block of code, Terraform will helpfully plan to destroy the corresponding live database or server. Catching unintended deletes here saves production environments.

### 4. Handling Dynamic Fetch Errors (The STS/Data block error)
If your code relies on `data` blocks to fetch real-time state from AWS (e.g., finding out which Availability Zones are currently online), `terraform plan` will attempt to execute those fetches immediately during the plan phase.

If you are using mock credentials (like we did with `skip_credentials_validation = true`), Terraform will successfully parse the static code (returning the `Plan: 25 to add` summary), but will ultimately throw a `403` or `401` error when it attempts the dynamic fetch:
> `Error: fetching Availability Zones... api error AuthFailure:`

This confirms the syntax is perfectly valid. The plan only failed because the mock credentials lack permissions to ask AWS for the dynamic list of AZs.
