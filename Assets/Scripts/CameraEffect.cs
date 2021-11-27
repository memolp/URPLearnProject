using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraEffect : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        Shader shader = Shader.Find("QING/RadialBlur");
        if(shader != null)
        {
            _Material = new Material(shader);
            Debug.Log("sdadasd");
        }    
        
    }
    public float _Force = 0.5f;
    Material _Material = null;
    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        Debug.Log("1111111111");
        if (_Material)
        {
            _Material.SetFloat("_Force", _Force);
            Graphics.Blit(source, destination, _Material);
            Debug.Log("2222222222");
        }
        else
        {
            Debug.Log("333333333333");
            Graphics.Blit(source, destination);
        }   
    } 
    // Update is called once per frame
    void Update()
    {
        
    }
}
