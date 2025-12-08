Santa's Finance Department
==========================

**Cron Meets Raku**

The Finance Department's computers had been converted to Debian Linux with *Rakuized* software along with all the other departments at the North Pole headquaters, and its employees enjoyed the Windows-free environment. However, an inspection by a firm hired to evaluate efficiency practices found some room for improvement.

Much of the work day was spent perusing email (as well as some postal mail) and entering purchase and payment information into the accounting software. The review team suggested that more automation was possible by investing in programs to (1) extract the information from the emails and (2) use optical character recognition (OCR) on digital scans of paper invoices.

The review team briefed Santa Claus and his department heads after their work was finished. After the team departed, Santa asked the IT department to assist the finance department in making the improvements.

Note the IT department is now using ChatGPT as a programming aid, so some of the new projects rely on it heavily for assistance in areas of little expertise as well as handling boiler plate (e.g., boring) coding. But any code used is tested thouroughly.

Extracting data from email
--------------------------

Gmail is the email system used currently with an address of "finance.santa@gmail.com" for the department. All bills and correspondence with external vendors use that address.

Normally Raku would be the programming language of choice, but Python is used for the interaction with Gmail because Google has well-defined Python APIs supported by Google.

In order to access Gmail programmatically, we need a secret token for our user. Following is the **one-time interactive process** using Python:

    cd /path/to/gmail-finance-ingest # a directory to contain most Python code
    python3 -m venv .venv
    . .venv/bin/activate
    pip install .
    gmail-finance-ingest init-auth \
      --credentials=/home/finance/secret/google/credentials.json \
      --token=/home/finance/secret/google/token.json

That launches the browser, the user approves access, that token is saved. After that, no more interaction is needed; `cron` (the Linux scheduler) can use the same token.

In order to handle the mail approriately, we use a `yaml` file to identify expected mail and its associated data as shown here in example file `config.yml`:

    data_root: /home/finance/gmail-bills

    sources:
      - name: city-utilities
        gmail_query: 'from:(billing@mycity.gov) has:attachment filename:pdf'
        expect: pdf
        subdir: city-utilities

      - name: electric-utility
        gmail_query: 'from:(noreply@powerco.com) subject:(Your bill) has:attachment filename:pdf'
        expect: pdf
        subdir: electric-utility

      - name: amazon
        gmail_query: 'from:(order-update@amazon.com OR auto-confirm@amazon.com)'
        expect: email
        subdir: amazon

Following is the `bash` script to handle the finance department's config file:

    . /home/finance/path/to/gmail-finance-ingest/.venv/bin/activate
    gmail-finance-ingest sync \
      --config=/home/fiance/gmail-finance-config.yml \
      --credentials=/home/finance/secret/google/credentials.json \
      --token=/home/finance/secret/google/token.json

### Automating the process

Linux `cron` is used to automate various email queries, thus saving a lot of manual, boring work by staff.

`cron` is a time-based job scheduler in Linux and other Unix-like operating systems. It enables users to schedule commands or scripts (known as cron jobs) to run automatically at specific times, dates, or intervals.

The driver program is a Python package named `gmail_finance_ingest`.

Here is the bash script used to operate on emails:

    #!/bin/bash
    set -e

    LOGDIR="$HOME/log"
    mkdir -p "$LOGDIR"

    # Activate venv
    . "$HOME/path/to/gmail-finance-ingest/.venv/bin/activate"

    gmail-finance-ingest sync \
      --config="$HOME/gmail-finance-config.yml" \
      --credentials="$HOME/secret/google/credentials.json" \
      --token="$HOME/secret/google/token.json" \
      >> "$LOGDIR/gmail-sync.log" 2>&1

Following is the `cron` code used to update email scans daily:

    15 3 * * * /home/finance/bin/run-gmail-sync.sh

For processing the data we handle several types which are identified in the expected emails and identified in the `config` file by the keywords shown below:

1. text embedded in the mail - `expect=email`

2. PDF attachments - `expect=pdf`

3. attachments or enclosed chunks of scanned documents - `expect=ocr`

Type 3 is not yet handled.

The collected data is parsed by type and the pertinent output is placed in CSV tables for bookkeeping purposes. Such tables can be used as source for Linux bookkeeping programs like [GnuCash](https://gnucash.org). The department has been using that program sincs the big Linux/Debian transition.

Emails which cannot be evaluated by machine are routed to clerks to handle manually.

Other work
----------

The IT folks have other projects not formally published yet, but some are in final testing stage and are usable now. See the summary below for related Raku projects such as an Access-like database program and a check-writing program.

Summary
-------

The products mentioned above are still works-in-progress, but their development can be followed on GitHub now at:

+ [Email::Monitor](https://github.com/tbrowder/Email-Monitor)

+ [Checkwriter](https://github.com/tbrowder/Checkwriter)

+ [CarolynDB](https://github.com/tbrowder/CarolynDB)

Epilogue
--------

Don't forget the "reason for the season:" ✝

As I always end these jottings, in the words of Charles Dickens' Tiny Tim, "**may God bless Us, Every one!**" [2]

Footnotes
---------

1. *A Christmas Carol*, a short story by Charles Dickens (1812-1870), a well-known and popular Victorian author whose many works include *The Pickwick Papers*, *Oliver Twist*, *David Copperfield*, *Bleak House*, *Great Expectations*, and *A Tale of Two Cities*.

