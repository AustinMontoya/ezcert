using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using ezcert.util;
using NDesk.Options;

namespace ezcert
{
  class Program
  {
    enum Subcommand
    {
      Unknown,
      UnlockConfigSection,
      InjectSecurityConfigSection,
      CreateClientCert,
      CreateCaCert
    }

    static void Main(string[] args) {
      var sub = GetSubcommand(args.FirstOrDefault());
      DoSubcommmand(sub, args.Skip(1).ToArray());
    }

    private static Subcommand GetSubcommand(string firstArg) {
      var operationArg = firstArg;
      if (string.IsNullOrEmpty(operationArg)) {
        Console.WriteLine("ERROR: Missing operation");
        return Subcommand.Unknown;
      }

      Subcommand sub;
      if (Enum.TryParse(firstArg, true, out sub)) return sub;

      Console.WriteLine($"ERROR: Unrecognized operation {operationArg}");
      return Subcommand.Unknown;
    }

    private static void DoSubcommmand(Subcommand command, string[] args) {

      switch (command) {
        case Subcommand.CreateCaCert:
          CreateCaCert(args);
          break;
        case Subcommand.CreateClientCert:
          CreateClientCert(args);
          break;
        case Subcommand.UnlockConfigSection:
          UnlockConfigSection(args);
          break;
        case Subcommand.InjectSecurityConfigSection:
          InjectConfigSection(args);
          break;
        default:
          ShowUsage();
          break;
      }
    }

    private static void InjectConfigSection(string[] args)
    {
      string configPath = null;
      new OptionSet
      {
        {"configPath=", v => configPath = v}
      }.Parse(args);

      if (string.IsNullOrEmpty(configPath)) {
        throw new ArgumentException("configPath is required");
      }

      EnvironmentUtils.InjectSecurityConfigSection(configPath);
    }

    private static void UnlockConfigSection(string[] args)
    {
      string configPath = null;
      new OptionSet
      {
        {"configPath=", v => configPath = v}
      }.Parse(args);


      if (string.IsNullOrEmpty(configPath))
      {
        throw new ArgumentException("configPath is required");
      }

      EnvironmentUtils.UnlockConfigSection(configPath);
    }


    private static void CreateClientCert(string[] args)
    {
      string name = null;
      string password = "password";
      string caPath = null;
      string caPassword = "password";
      string outputPath = Path.Combine(Environment.CurrentDirectory, $"{name}.pfx");

      new OptionSet
      {
        {"name=", (v) => name = v},
        {"password=", (v) => password = v},
        {"caPath=", (v) => caPath = v},
        {"caPassword=", (v) => caPassword = v},
        {"outputPath=", (v) => outputPath = v}
      }.Parse(args);

      if (string.IsNullOrEmpty(name))
      {
        throw new ArgumentException("Name is required");
      }

      if (string.IsNullOrEmpty(caPath))
      {
        throw new ArgumentException("caPath is required");
      }

      var caCert = CertUtils.LoadCertificate(caPath, caPassword);
      var clientCert = CertUtils.IssueCertificate(name, caCert);
      CertUtils.WriteCertificate(clientCert, password, outputPath);
    }

   

    private static void CreateCaCert(string[] args) {
      string name = null;
      string password = "password";
      string outputPath = Path.Combine(Environment.CurrentDirectory, $"{name}.pfx"); 

      new OptionSet
      {
        {"name=", (v) => name = v},
        {"password=", (v) => password = v},
        {"outputPath=", (v) => outputPath = v}
      }.Parse(args);

      if (string.IsNullOrEmpty(name)) {
        throw new ArgumentException("Name is required");
      }

      var cert = CertUtils.CreateCertificateAuthorityCertificate(name, password);
      CertUtils.WriteCertificate(cert, password, outputPath);
    }

    private static void ShowUsage() {
      Console.Write("Usage: ezcert <operation> [options...]");
    }

  }


}
