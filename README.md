# PTT Postal Code Scraper

This script scrapes postal code data from the [Turkish Postal Service (PTT) website](https://postakodu.ptt.gov.tr/). It collects information about cities, districts, and neighborhoods, including postal codes.

## Requirements

- Ruby
- `faraday` gem Simple, but flexible HTTP client library, with support for multiple backends.
- `nokogiri` gem Nokogiri (鋸) makes it easy and painless to work with XML and HTML from Ruby.

## Installation

```bash
git clone https://github.com/aydinkazim/neighbourhoods-in-turkey.git
cd neighbourhoods-in-turkey
ruby neighbourhoods-in-turkey.rb 
```