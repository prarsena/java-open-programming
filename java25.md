The new `java.lang.IO` class in Java 25 is the centerpiece of a major initiative to make Java more "compact" and beginner-friendly. Historically, students had to memorize the "mysterious incantation" of `System.out.println` before they even understood what a class or a static field was.

In Java 25, the `IO` class effectively acts as a cleaner, more readable bridge to the console.

---

### 1. Key Features of the `IO` Class

The `IO` class is designed to handle the most common tasks—printing text and reading user input—without the boilerplate of `Scanner` or `BufferedReader`.

* **Implicitly Imported:** Because it lives in `java.lang`, you don't need an `import` statement to use it. You can just type `IO.println()`.
* **Static Methods:** Every method in the `IO` class is `static`, meaning you never need to say `new IO()`.
* **Streamlined Logic:** Behind the scenes, it maps directly to `System.out` (for writing) and `System.in` (for reading).

---

### 2. The Core Methods

There are only a few methods to learn, which is by design. They cover approximately 90% of what a student needs in their first semester.

| Method | Description | Equivalent to... |
| --- | --- | --- |
| `IO.print(Object obj)` | Prints text to the terminal without a new line. | `System.out.print()` |
| `IO.println(Object obj)` | Prints text and moves the cursor to a new line. | `System.out.println()` |
| `IO.readln()` | Pauses the program and waits for the user to type a line. | `Scanner.nextLine()` |
| `IO.readln(String prompt)` | Prints a message (like "Enter name: ") and then reads input. | `print` + `readLine` |

---

### 3. Comparison: The "Old" Way vs. The "Java 25" Way

This is the best way to visualize how much "mental load" is removed for a student.

#### Reading a name and printing a greeting:

**Before (The "Wall of Concepts"):**

```java
import java.util.Scanner;

public class Greet {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("Enter name: ");
        String name = sc.nextLine();
        System.out.println("Hello, " + name);
    }
}

```

**After (The "Compact" Style):**

```java
void main() {
    String name = IO.readln("Enter name: ");
    IO.println("Hello, " + name);
}

```

---

### 4. Why "IO.println" and not just "println"?

In earlier previews (JDK 21/22), the methods were "magically" available without even typing `IO.`. However, the Java architects decided to make the class name explicit (`IO.println`) for two reasons:

1. **Clarity:** It’s clear that `println` belongs to the `IO` class.
2. **Tooling:** When a student types `IO.` in VS Code or IntelliJ, the IDE can suggest the available methods (Autocomplete), making it easier for them to discover `readln` on their own.

### 5. Transitioning to "Real" Java

The `IO` class is not a "toy." It is a permanent part of the `java.base` module. As your students grow into more complex programming:

* They can keep using `IO` for quick debugging.
* They can switch to `System.out` when they need more granular control over streams.
* They can switch to `Scanner` when they need to parse specific data types (like `nextInt()`).

[Setting up Java 25 and IO class in IntelliJ](https://www.youtube.com/watch?v=hQz9Lw6VdGw)

This short video clarifies that there is "no magic" behind the new `IO` class—it's a standard class in the `java.lang` package that simplifies common tasks for modern Java development.