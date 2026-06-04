terraform {
  required_version = ">= 1.6.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

locals {
  project = "aws-accelerator-p2"
  week    = "w8"
  day     = "day-a"
}

resource "local_file" "learning_note" {
  filename = "${path.module}/generated-note.txt"
  content  = "Project: ${local.project}\nWeek: ${local.week}\nDay: ${local.day}\nTopic: Terraform basics\n"
}

output "note_path" {
  description = "Generated learning note path."
  value       = local_file.learning_note.filename
}

