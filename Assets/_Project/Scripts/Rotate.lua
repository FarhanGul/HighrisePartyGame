function self:Update()
    local rotationAngle = 5 * Time.deltaTime
    self.transform.localEulerAngles = self.transform.localEulerAngles + Vector3.new(0, rotationAngle, 0);
end