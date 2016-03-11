# Overview

This is a standalone powershell module intended to simplify the local setup of SSL Certificate Authentication in ASP.Net projects.

What it does:

- Creates a new local Certificate Authority (and optionally imports it into the correct certificate store)
- Creates a client certificate signed by the certificate authority (and optionally imports it into the correct store)
- Unlocks the correct config section in applicationhost.config needed to enable client certs in your project(s)
- Injects boilerplate into your web.config to enable client certificate authentication

What it doesn't do:

- Create certificates suitable for production use
- Set up [Client Certificate Mapping Auth](https://www.iis.net/configreference/system.webserver/security/authentication/iisclientcertificatemappingauthentication)

# Installation

Quick way:

```powershell
(new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/grrizzly/ezcert/master/install.ps1") | iex
```

(You are encouraged to look at the installation script before running it!)

Manual way:

1. Go to the [releases page](https://github.com/grrizzly/ezcert/releases) 
1. Download `package.zip` associated with the version you want to install
1. Unzip the contents into your `~\Documents\WindowsPowerShell\Modules` folder, in a new folder named "ezcert"
1. Kill your current terminal session and start a new one.

# Usage

This module adds four single-purpose commands for various setup tasks, and one "quick" command that abstracts the normal flow of commands needed to set up a new project.

#### `Initialize-LocalClientCerts`

Creates and installs a default Certificate Authority, issues/installs a client cert using that authority, optionally unlocks the `<access>` element in appropriate `applicationhost.config` (default `Y`), and optionally injects boilerplate into your web.config (default `N`).

This is usually the best choice for simple projects, or if you're trying this library out for the first time.

##### Options:
 
- `-Auto {$true | $false}`: When enabled, does not prompt the user for information and instead uses the default options. Note that this means it will not run in interactive mode. Defaults to `$false`. You are highly encouraged to leave this set to `$true` the first time you run `Initialize-LocalClientCerts`, as it give you a better understanding of what actually happens when this command is run.

#### `New-LocalCA`

Creates and optionally installs a Certificate Authority (CA). Provides an exported .pfx containing the public and private key.

When using the defaults, this command will skip creation if a certificate with the same CN (`localCA`) is found in `Cert:\LocalMachine\Root`. If something goes wrong and you want to regenerate the default CA, delete any cert(s) named `localCA` in your Local Machine - Trusted Root Certification Authorities store.

##### Options:

- `-Name [string]`: The [Common Name](https://support.dnsimple.com/articles/what-is-common-name/) to add to the certificate. Defaults to `localCA`. Many guides indicate that this should match a domain, but this isn't a hard requirement. 
- `-Password [string]`: The password used to protect the private key. Defaults to `password`. 
- `-OutputPath [string]`: The full path to save the .pfx export in. Defaults to `$PWD\$Name.pfx`
- `-AutoImport [bool]`: Indicates whether to automatically import the certificate into your Local Machine's Trusted Root Certification Authorities certificate store. Defaults to `$true`. Note that the imported CA can also be exported using the password provided by the `Password` param. Also note that this will attempt to launch an elevated prompt, so make sure your user can elevate to Administrator privileges.

#### `New-LocalClientCert`

Creates and optionally installs a client certificate using a given CA. 

If attempting to use the default CA and it does not exist, it will be created.

##### Options:

- `-Name [string]`: The Common Name for the certificate. Defaults to `clientCertificate`.
- `-Password [string]`: The password used to protect the private key. Defaults to `password`.
- `-OutputFileName [string]`: The name of the file to save the .pfx export in. Defaults to `clientCertificate.pfx`.
- `-AutoImport [bool]`:  Indicates whether to automatically import the certificate into your user's Personal certificate store. Defaults to `$true`.
- `-UseDefaultCa [bool]`: Looks for an existing CA in your Local Machine's trusted store matching the default CA's name (`localCA`). If found, it will use this CA to issue the client certificate.
- `-CaPath [string]`: The path to a custom CA if not using the default. 
- `-CaPassword [string]`: The password for the custom CA if not using the default.

#### `Unlock-AppHostSecuritySection`

Updates an `applicationhost.config` file, changing the `<section name="access">` element's `overrideModeDefault` property to `Allow`, enabling applications using this config to specify their own SSL configuration.

##### Options:

- `-Path [string]`: The path to the `applicationhost.config` file. If not provided, this command will, starting in the current directory, look for a file at `.vs\config\applicationhost.config`, traversing upwards until it hits the root path. If no such file exists, this command checks for the global IISExpress configuration, located at `~\Documents\IISExpress\config\applicationhost.config`. When no suitable file is found, it will throw an error.

#### `Initialize-ClientCertConfig`

Updates a `web.config` file, adding in the basic boilerplate to enable client certificate authentication for a particlar project. Specifically, it adds the following subtree to `<system.webServer>`:

```xml
<security>
    <access sslFlags="Ssl,SslRequireCert,SslNegotiateCert" />
</security>
```

Tips:

- To make client certificate authentication optional, remove the `SslRequireCert` flag from the attribute value.
- If you would like to only enable client certificate authentication for part of your application, consider moving the element into a separate `<location>` element, e.g.

```xml
<location path="services">
  <system.webServer>
    <security>
      <access sslFlags="Ssl,SslNegotiateCert,SslRequireCert" />
    </security>
  </system.webServer>
</location>
```

##### Options:

- `-Path [string]`: The path to the `web.config` file. If not provided, this command will, starting in the current directory, search for a `web.config` file, traversing upward until it reaches the drive root. It will throw an error if no file is found.