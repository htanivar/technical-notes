
### Bash Script to Create a Complex JSON File

Create a bash script named `create_complex_json.sh` to generate a complex JSON file:

```bash
#!/bin/bash

cat << EOF > complex.json
[
  {
    "government": {
      "name": "india",
      "state": [
        {
          "name": "tamilnadu",
          "skills": [
            "rise",
            "education",
            "temple"
          ]
        },
        {
          "name": "bihar",
          "skills": [
            "labur",
            "population"
          ]
        },
        {
          "name": "maharastra",
          "skills": [
            "economy",
            "sharemarket"
          ]
        },
        {
          "name": "gujarat",
          "skills": [
            "business",
            "sweets"
          ]
        }
      ]
    }
  },
  {
    "school": {
      "name": "Madras University",
      "students": [
        {
          "name": "Alice",
          "age": 30,
          "department": "Engineering",
          "projects": [
            {
              "name": "Project A",
              "status": "Completed",
              "budget": 100000
            },
            {
              "name": "Project B",
              "status": "In Progress",
              "budget": 50000
            }
          ],
          "skills": [
            "JavaScript",
            "React",
            "Node.js"
          ]
        },
        {
          "name": "Bob",
          "age": 25,
          "department": "Marketing",
          "projects": [
            {
              "name": "Project X",
              "status": "Completed",
              "budget": 30000
            },
            {
              "name": "Project Y",
              "status": "In Progress",
              "budget": 20000
            }
          ],
          "skills": [
            "SEO",
            "Content Creation"
          ]
        },
        {
          "name": "Charlie",
          "age": 35,
          "department": "Human Resources",
          "projects": [],
          "skills": [
            "Recruitment",
            "Employee Relations"
          ]
        }
      ],
      "locations": [
        {
          "city": "salem",
          "address": "adivaram",
          "student_count": 150
        },
        {
          "city": "chennai",
          "address": "beach",
          "student_count": 200
        }
      ],
      "fees": {
        "college": 1000000,
        "hostel": 750000
      }
    }
  },
  {
    "company": {
      "name": "TechCorp",
      "employees": [
        {
          "name": "Alice",
          "age": 30,
          "department": "Engineering",
          "projects": [
            {
              "name": "Project A",
              "status": "Completed",
              "budget": 100000
            },
            {
              "name": "Project B",
              "status": "In Progress",
              "budget": 50000
            }
          ],
          "skills": [
            "JavaScript",
            "React",
            "Node.js"
          ]
        },
        {
          "name": "Bob",
          "age": 25,
          "department": "Marketing",
          "projects": [
            {
              "name": "Project X",
              "status": "Completed",
              "budget": 30000
            },
            {
              "name": "Project Y",
              "status": "In Progress",
              "budget": 20000
            }
          ],
          "skills": [
            "SEO",
            "Content Creation"
          ]
        },
        {
          "name": "Charlie",
          "age": 35,
          "department": "Human Resources",
          "projects": [],
          "skills": [
            "Recruitment",
            "Employee Relations"
          ]
        }
      ],
      "locations": [
        {
          "city": "New York",
          "address": "123 Main St",
          "employees_count": 150
        },
        {
          "city": "San Francisco",
          "address": "456 Market St",
          "employees_count": 200
        }
      ],
      "financials": {
        "revenue": 1000000,
        "expenses": 750000,
        "profit": 250000
      }
    }
  }
]
EOF

echo "Complex JSON file 'complex.json' created successfully."
