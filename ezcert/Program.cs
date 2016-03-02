using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using ezcert.util;
using NDesk.Options;

namespace ezcert
{
  class Program
  {
    static class Operations
    {
      public const string CreateCa = "createca";
      public const string CreateClientCert = "createclientcert";

      public static string Get(string arg)
      {
        switch (arg.ToLower())
        {
          case CreateCa:
            return CreateCa;
          case CreateClientCert:
            return CreateClientCert;
          default:
            return string.Empty;
        }
      }
    }
    static void Main(string[] args)
    {
      var operation = GetOperation(args.FirstOrDefault());
      if (string.IsNullOrEmpty(operation))
      {
        ShowUsage();
        return;
      } 

      DoOperation(operation, args.Skip(1));
    }

    private static string GetOperation(string firstArg)
    {
      var operationArg = firstArg;
      if (string.IsNullOrEmpty(operationArg) || new Regex("^(--?|\\/)").IsMatch(operationArg)) {
        Console.WriteLine("ERROR: Missing operation");
        return string.Empty;
      }

      var operation = Operations.Get(operationArg);
      if (string.IsNullOrEmpty(operation)) {
        Console.WriteLine($"ERROR: Unrecognized operation {operationArg}");
        return string.Empty;
      }

      return operation;
    }

    private static void DoOperation(string operation, IEnumerable<string> args)
    {
      var certName = string.Empty;
      var caPath = string.Empty;
      var caPassword = string.Empty;
      var outputFile = "out.pfx";

      var optionSet = new OptionSet()
      {
        {"CertName=", v => certName = v},
        {"CaPath=", v => caPath = v },
        {"CaPassword=", v => caPassword = v ?? "password" },
        {"OutputFile=", v => outputFile = v }
      };

      optionSet.Parse(args);

      if (string.IsNullOrEmpty(certName))
      {
        Console.WriteLine("ERROR: -CertName is required");
        ShowUsage();
        return;
      }

      if (operation == Operations.CreateCa)
      {
        if (string.IsNullOrEmpty(caPath))
        {
          Console.WriteLine("ERROR: -CaPath is required");
        }
        var cert = CertUtils.CreateCertificateAuthorityCertificate(certName, caPassword);
        CertUtils.WriteCertificate(cert, caPassword, outputFile);
      }

      if (operation == Operations.CreateClientCert)
      {
        var caCert = CertUtils.LoadCertificate(caPath, caPassword);
        var cert = CertUtils.IssueCertificate(certName, caCert);
        CertUtils.WriteCertificate(cert, null, outputFile);
      }
    }

    private static void ShowUsage()
    {
      Console.Write("Usage: ezcert <operation> [options...]");
    }

  }

  
}
