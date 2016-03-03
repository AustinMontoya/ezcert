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
        path = FindApplicationHostConfig(Environment.CurrentDirectory);
        if (path == null) throw new InvalidOperationException("No applicationhost.config found in a .vs or documents folder");
      }
      
      var doc = XDocument.Load(path);
      var element = doc.XPathSelectElement("//sectionGroup[@name='security']/section[@name='access']");
      element.SetAttributeValue(XName.Get("overrideModeDefault"), "Allow");
      doc.Save(path);
    }

 
    private static string FindApplicationHostConfig(string path)
    {
      if (path == Path.GetPathRoot(path))
      {
        var globalConfigPath = Path.Combine(path, "Users", Environment.UserName, "Documents", "IISExpress", "config", "applicationhost.config");
        return File.Exists(globalConfigPath) ? globalConfigPath : null;
      }

      var localConfigPath = Path.Combine(path, ".vs", "config", "applicationhost.config");
      return File.Exists(localConfigPath)
        ? localConfigPath
        : FindApplicationHostConfig(Directory.GetParent(path).FullName);
    }
  }
}