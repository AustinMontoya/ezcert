using System;
using System.IO;
using System.Xml.Linq;
using System.Xml.XPath;

namespace ezcert.util
{
  public class EnvironmentUtils
  {
    public static void UnlockConfigSection(string path)
    {
      if (string.IsNullOrEmpty(path))
      {
        throw new ArgumentException("Path is required");
      }
      
      var doc = XDocument.Load(path);
      var element = doc.XPathSelectElement("//sectionGroup[@name='security']/section[@name='access']");
      element.SetAttributeValue(XName.Get("overrideModeDefault"), "Allow");
      doc.Save(path);
    }


    public static void InjectSecurityConfigSection(string path)
    {
      if (string.IsNullOrEmpty(path))
      {
        throw new ArgumentException("Path is required");
      }

      var doc = XDocument.Load(path);
      var webServerElement = doc.XPathSelectElement("//system.webServer");
      var securityElement = SelectOrCreateElement(webServerElement, "//security", "security");
      var accessElement = SelectOrCreateElement(securityElement, "access", "access");

      accessElement.SetAttributeValue(XName.Get("sslFlags"), "Ssl,SslRequireCert,SslNegotiateCert");
      doc.Save(path);
    }

    private static XElement SelectOrCreateElement(XContainer parent, string xpath, string name)
    {
      var element = parent.XPathSelectElement(xpath);
      if (element != null) return element;

      element = new XElement(XName.Get(name));
      parent.AddFirst(element);
      return element;
    }
  }
}