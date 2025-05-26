using UnityEngine;

public class DragObject : MonoBehaviour
{
    private Vector3 offset;
    private float zCoord;
    private Rigidbody rb;
    private bool isDragging = false;
    private Vector3 lastValidPosition;

    void Start()
    {
        rb = GetComponent<Rigidbody>();
        lastValidPosition = transform.position; // Başlangıç pozisyonunu kaydet
    }

    void OnMouseDown()
    {
        isDragging = true;
        zCoord = Camera.main.WorldToScreenPoint(transform.position).z;
        offset = transform.position - GetMouseWorldPos();
        
        if(rb != null)
        {
            rb.isKinematic = true;
            rb.useGravity = false;
        }
    }

    void OnMouseDrag()
    {
        if (isDragging)
        {
            transform.position = GetMouseWorldPos() + offset;
        }
    }

    void OnMouseUp()
    {
        isDragging = false;
        
        if(rb != null)
        {
            rb.isKinematic = false;
            rb.useGravity = true;
        }

        // Placement area'da olup olmadığını kontrol et
        Collider[] hitColliders = Physics.OverlapSphere(transform.position, 0.1f);
        bool isInPlacementArea = false;
        
        foreach (var hitCollider in hitColliders)
        {
            if (hitCollider.GetComponent<PlacementArea>() != null)
            {
                isInPlacementArea = true;
                lastValidPosition = transform.position;
                transform.position = new Vector3(transform.position.x, 0.5f, transform.position.z);
                break;
            }
        }

        if (!isInPlacementArea)
        {
            // Eğer placement area'da değilse son geçerli pozisyona geri dön
            transform.position = lastValidPosition;
        }
    }

    Vector3 GetMouseWorldPos()
    {
        Vector3 mousePoint = Input.mousePosition;
        mousePoint.z = zCoord;
        return Camera.main.ScreenToWorldPoint(mousePoint);
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.GetComponent<PlacementArea>() != null)
        {
            lastValidPosition = transform.position;
        }
    }
} 