Dryad-Zenodo Integration
==========================

Dryad and Zenodo are partnering to provide researchers with a more
seamless publishing process for data, code, and other materials.

This directory contains documentation of Dryad features related to the partnership.

## InvenioRDM version setup

Zenodo has changed a few things in their new instance.  They are
using what seems like a more standard OAuth2 setup. This means that
they do not automataically supply a token to users, but one can be
obtained with the client_credentials grant type and using the client
id and secret.

Typically this could be done with a curl command like below or with
an http library in a programming language.

```bash
curl -X POST https://zenodo-rdm-qa.web.cern.ch/oauth/token -d "client_id=<omitted>&client_secret=<omitted>&grant_type=client_credentials&scope=&scope=deposit%3Awrite+deposit%3Aactions"
```

I understand the scopes are `deposit:write` and `deposit:actions` but I
continue to get an invalid scope error when I try to use them.  The client type
should be set to `confidential` in their UI setup page.

