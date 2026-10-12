# JointForge in one minute

**Create:** Select one part, assign Part0. Select the other, assign Part1. Choose the joint type, Preview, then Apply. For a hinge, choose existing pivot attachments if the midpoint is not the intended hinge location.

**Assemble a tool:** In Batch, assign the Handle as root. Select fixed pieces and choose Static. Select moving pieces and choose Moving. Review Preview; resolve any blocked connections explicitly. Apply once.

**Inspect:** Select a model and click Inspect current selection. Open a joint to select either endpoint or locate it in Explorer. C0/C1 use six numbers: position XYZ, then rotation XYZ in degrees. Reset means identity and can move the assembly.

**Undo:** Use Studio Undo once after Apply. Redo restores the operation. Work in edit mode, not Play.

JointForge never automatically removes old connections, changes Anchored or fixes collisions. Test physical motion in a copy of your place after setup.
