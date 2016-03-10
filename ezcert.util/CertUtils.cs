using System;
using System.IO;
using System.Security.Cryptography.X509Certificates;
using Org.BouncyCastle.Asn1.X509;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Generators;
using Org.BouncyCastle.Crypto.Prng;
using Org.BouncyCastle.Math;
using Org.BouncyCastle.Pkcs;
using Org.BouncyCastle.Security;
using Org.BouncyCastle.Utilities;
using Org.BouncyCastle.X509;
using X509Certificate = Org.BouncyCastle.X509.X509Certificate;

namespace ezcert.util
{
  public static class CertUtils
  {

    public static X509Certificate2 LoadCertificate(string issuerFileName, string password) {
      // We need to pass 'Exportable', otherwise we can't get the private key.
      var issuerCertificate = new X509Certificate2(issuerFileName, password, X509KeyStorageFlags.Exportable);
      return issuerCertificate;
     
    }

    public static X509Certificate2 LoadCaCertifcate(string name)
    {
      var store = new X509Store("Root", StoreLocation.LocalMachine);
      store.Open(OpenFlags.ReadOnly);
      var matches = store.Certificates.Find(X509FindType.FindBySubjectDistinguishedName, $"CN={name}", true);
      store.Close();
      if (matches.Count < 1) return null;
      return new X509Certificate2(matches[0].Export(X509ContentType.Pkcs12, "password"), "password", X509KeyStorageFlags.Exportable);
    }

    public static X509Certificate2 IssueCertificate(string commonName, string caName)
    {
      return IssueCertificate(commonName, LoadCaCertifcate(caName));
    }
    

    public static X509Certificate2 IssueCertificate(string commonName, X509Certificate2 issuerCertificate) {
      // It's self-signed, so these are the same.
      var issuerName = issuerCertificate.Subject;

      var random = GetSecureRandom();
      var subjectKeyPair = GenerateKeyPair(random, 2048);

      var issuerKeyPair = DotNetUtilities.GetKeyPair(issuerCertificate.PrivateKey);

      var serialNumber = GenerateSerialNumber(random);
      
      var certificate = GenerateCertificate(random, commonName, subjectKeyPair, serialNumber, issuerName, issuerKeyPair);
      return ConvertCertificate(certificate, subjectKeyPair, random);
    }

    public static X509Certificate2 CreateCertificateAuthorityCertificate(string name, string password)
    {
      if (name == null) throw new ArgumentNullException(nameof(name));
      
      // It's self-signed, so these are the same.
      var issuerName = name;

      var random = GetSecureRandom();
      var subjectKeyPair = GenerateKeyPair(random, 2048);

      // It's self-signed, so these are the same.
      var issuerKeyPair = subjectKeyPair;

      var serialNumber = GenerateSerialNumber(random);
      var issuerSerialNumber = serialNumber; // Self-signed, so it's the same serial number.
      
      var certificate = GenerateCertificate(random, name, subjectKeyPair, serialNumber, GetCommonName(issuerName), issuerKeyPair);
      return ConvertCertificate(certificate, subjectKeyPair, random);
    }

    public static X509Certificate2 CreateSelfSignedCertificate(string subjectName)
    {

      // It's self-signed, so these are the same.
      var issuerName = subjectName;

      var random = GetSecureRandom();
      var subjectKeyPair = GenerateKeyPair(random, 2048);

      // It's self-signed, so these are the same.
      var issuerKeyPair = subjectKeyPair;

      var serialNumber = GenerateSerialNumber(random);

      var certificate = GenerateCertificate(random, subjectName, subjectKeyPair, serialNumber, issuerName, issuerKeyPair);
      return ConvertCertificate(certificate, subjectKeyPair, random);
    }

    private static SecureRandom GetSecureRandom() {
      // Since we're on Windows, we'll use the CryptoAPI one (on the assumption
      // that it might have access to better sources of entropy than the built-in
      // Bouncy Castle ones):
      var randomGenerator = new CryptoApiRandomGenerator();
      var random = new SecureRandom(randomGenerator);
      return random;
    }

    private static X509Certificate GenerateCertificate(SecureRandom random,
                                                       string subjectName,
                                                       AsymmetricCipherKeyPair subjectKeyPair,
                                                       BigInteger subjectSerialNumber,
                                                       string issuerName,
                                                       AsymmetricCipherKeyPair issuerKeyPair)
    {
      
      var certificateGenerator = new X509V3CertificateGenerator();

      certificateGenerator.SetSerialNumber(subjectSerialNumber);

      // Set the signature algorithm. This is used to generate the thumbprint which is then signed
      // with the issuer's private key. We'll use SHA-256, which is (currently) considered fairly strong.
      const string signatureAlgorithm = "SHA256WithRSA";
      certificateGenerator.SetSignatureAlgorithm(signatureAlgorithm);

      var issuerDN = new X509Name(issuerName);
      certificateGenerator.SetIssuerDN(issuerDN);

      // Note: The subject can be omitted if you specify a subject alternative name (SAN).
      var subjectDN = new X509Name(GetCommonName(subjectName));
      certificateGenerator.SetSubjectDN(subjectDN);

      // Our certificate needs valid from/to values.
      var notBefore = DateTime.UtcNow.Date;
      var notAfter = notBefore.AddYears(2);

      certificateGenerator.SetNotBefore(notBefore);
      certificateGenerator.SetNotAfter(notAfter);

      // The subject's public key goes in the certificate.
      certificateGenerator.SetPublicKey(subjectKeyPair.Public);

      var certificate = certificateGenerator.Generate(issuerKeyPair.Private, random);
      return certificate;
    }

    /// <summary>
    /// The certificate needs a serial number. This is used for revocation,
    /// and usually should be an incrementing index (which makes it easier to revoke a range of certificates).
    /// Since we don't have anywhere to store the incrementing index, we can just use a random number.
    /// </summary>
    /// <param name="random"></param>
    /// <returns></returns>
    private static BigInteger GenerateSerialNumber(SecureRandom random) {
      var serialNumber =
          BigIntegers.CreateRandomInRange(
              BigInteger.One, BigInteger.ValueOf(Int64.MaxValue), random);
      return serialNumber;
    }

    /// <summary>
    /// Generate a key pair.
    /// </summary>
    /// <param name="random">The random number generator.</param>
    /// <param name="strength">The key length in bits. For RSA, 2048 bits should be considered the minimum acceptable these days.</param>
    /// <returns></returns>
    private static AsymmetricCipherKeyPair GenerateKeyPair(SecureRandom random, int strength) {
      var keyGenerationParameters = new KeyGenerationParameters(random, strength);

      var keyPairGenerator = new RsaKeyPairGenerator();
      keyPairGenerator.Init(keyGenerationParameters);
      var subjectKeyPair = keyPairGenerator.GenerateKeyPair();
      return subjectKeyPair;
    }

    

    private static X509Certificate2 ConvertCertificate(X509Certificate certificate,
                                                       AsymmetricCipherKeyPair subjectKeyPair,
                                                       SecureRandom random) {
      // Now to convert the Bouncy Castle certificate to a .NET certificate.
      // See http://web.archive.org/web/20100504192226/http://www.fkollmann.de/v2/post/Creating-certificates-using-BouncyCastle.aspx
      // ...but, basically, we create a PKCS12 store (a .PFX file) in memory, and add the public and private key to that.
      var store = new Pkcs12Store();

      // What Bouncy Castle calls "alias" is the same as what Windows terms the "friendly name".
      string friendlyName = certificate.SubjectDN.ToString();

      // Add the certificate.
      var certificateEntry = new X509CertificateEntry(certificate);
      store.SetCertificateEntry(friendlyName, certificateEntry);

      // Add the private key.
      store.SetKeyEntry(friendlyName, new AsymmetricKeyEntry(subjectKeyPair.Private), new[] { certificateEntry });

      // Convert it to an X509Certificate2 object by saving/loading it from a MemoryStream.
      // It needs a password. Since we'll remove this later, it doesn't particularly matter what we use.
      const string password = "password";
      var stream = new MemoryStream();
      store.Save(stream, password.ToCharArray(), random);

      var convertedCertificate =
          new X509Certificate2(stream.ToArray(),
                               password,
                               X509KeyStorageFlags.PersistKeySet | X509KeyStorageFlags.Exportable);
      return convertedCertificate;
    }

    private static string GetCommonName(string name)
    {
      return "CN=" + name;
    }

    public static void WriteCertificate(X509Certificate2 certificate, string password, string outputFileName) {
      var bytes = certificate.Export(X509ContentType.Pfx, password);
      File.WriteAllBytes(outputFileName, bytes);
    }

  }
}