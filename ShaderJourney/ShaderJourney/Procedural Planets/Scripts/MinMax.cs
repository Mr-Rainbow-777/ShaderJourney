public class MinMax 
{
    public float Min;
    public float Max;

    public MinMax()
    {
        Min = float.MaxValue;
        Max = float.MinValue;
    }


    public void AddValue(float value)
    {
        if(value>Max) Max = value;
        if(value<Min) Min = value;  
    }
}
