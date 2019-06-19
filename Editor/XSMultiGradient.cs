using System.Collections.Generic;
using UnityEngine;
public class XSMultiGradient : ScriptableObject {
	public string uniqueName = "New Gradient";
	public List<Gradient> gradients = new List<Gradient>();
	public List<int> order = new List<int>();
}