/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.http;

import uim.net.core.App;
import uim.net.http.Middleware\ClosureDecoratorMiddleware;
import uim.net.http.Middleware\DoublePassDecoratorMiddleware;
use Closure;
use Countable;
use LogicException;
use OutOfBoundsException;
use Psr\Http\servers.IMiddleware;
use ReflectionFunction;
use UIMException;
use SeekableIterator;

/**
 * Provides methods for creating and manipulating a "queue" of middlewares.
 * This queue is used to process a request and generate response via uim.net.http\Runner.
 *
 * @template-implements \SeekableIterator<int, \Psr\Http\servers.IMiddleware>
 */
class MiddlewareQueue : Countable, SeekableIterator
{
    /**
     * Internal position for iterator.
     */
    protected int $position = 0;

    /**
     * The queue of middlewares.
     *
     * @var array<int, mixed>
     */
    protected $queue = null;

    /**
     * Constructor
     *
     * @param array $middleware The list of middleware to append.
     */
    this(array $middleware = null) {
        this.queue = $middleware;
    }

    /**
     * Resolve middleware name to a PSR 15 compliant middleware instance.
     *
     * @param \Psr\Http\servers.IMiddleware|\Closure|string $middleware The middleware to resolve.
     * @return \Psr\Http\servers.IMiddleware
     * @throws \UIMException If Middleware not found.
     */
    protected function resolve($middleware): IMiddleware
    {
        if (is_string($middleware)) {
            $className = App::className($middleware, "Middleware", "Middleware");
            if ($className == null) {
                throw new UIMException(sprintf(
                    "Middleware '%s' was not found.",
                    $middleware
                ));
            }
            $middleware = new $className();
        }

        if ($middleware instanceof IMiddleware) {
            return $middleware;
        }

        if (!$middleware instanceof Closure) {
            return new DoublePassDecoratorMiddleware($middleware);
        }

        $info = new ReflectionFunction($middleware);
        if ($info.getNumberOfParameters() > 2) {
            return new DoublePassDecoratorMiddleware($middleware);
        }

        return new ClosureDecoratorMiddleware($middleware);
    }

    /**
     * Append a middleware to the end of the queue.
     *
     * @param \Psr\Http\servers.IMiddleware|\Closure|array|string $middleware The middleware(s) to append.
     * @return this
     */
    function add($middleware) {
        if (is_array($middleware)) {
            this.queue = array_merge(this.queue, $middleware);

            return this;
        }
        this.queue ~= $middleware;

        return this;
    }

    /**
     * Alias for MiddlewareQueue::add().
     *
     * @param \Psr\Http\servers.IMiddleware|\Closure|array|string $middleware The middleware(s) to append.
     * @return this
     * @see MiddlewareQueue::add()
     */
    function push($middleware) {
        return this.add($middleware);
    }

    /**
     * Prepend a middleware to the start of the queue.
     *
     * @param \Psr\Http\servers.IMiddleware|\Closure|array|string $middleware The middleware(s) to prepend.
     * @return this
     */
    function prepend($middleware) {
        if (is_array($middleware)) {
            this.queue = array_merge($middleware, this.queue);

            return this;
        }
        array_unshift(this.queue, $middleware);

        return this;
    }

    /**
     * Insert a middleware at a specific index.
     *
     * If the index already exists, the new middleware will be inserted,
     * and the existing element will be shifted one index greater.
     *
     * @param int $index The index to insert at.
     * @param \Psr\Http\servers.IMiddleware|\Closure|string $middleware The middleware to insert.
     * @return this
     */
    function insertAt(int $index, $middleware) {
        array_splice(this.queue, $index, 0, [$middleware]);

        return this;
    }

    /**
     * Insert a middleware before the first matching class.
     *
     * Finds the index of the first middleware that matches the provided class,
     * and inserts the supplied middleware before it.
     *
     * @param string $class The classname to insert the middleware before.
     * @param \Psr\Http\servers.IMiddleware|\Closure|string $middleware The middleware to insert.
     * @return this
     * @throws \LogicException If middleware to insert before is not found.
     */
    function insertBefore(string $class, $middleware) {
        $found = false;
        $i = 0;
        foreach (this.queue as $i: $object) {
            /** @psalm-suppress ArgumentTypeCoercion */
            if (
                (
                    is_string($object)
                    && $object == $class
                )
                || is_a($object, $class)
            ) {
                $found = true;
                break;
            }
        }
        if ($found) {
            return this.insertAt($i, $middleware);
        }
        throw new LogicException(sprintf("No middleware matching '%s' could be found.", $class));
    }

    /**
     * Insert a middleware object after the first matching class.
     *
     * Finds the index of the first middleware that matches the provided class,
     * and inserts the supplied middleware after it. If the class is not found,
     * this method will behave like add().
     *
     * @param string $class The classname to insert the middleware before.
     * @param \Psr\Http\servers.IMiddleware|\Closure|string $middleware The middleware to insert.
     * @return this
     */
    function insertAfter(string $class, $middleware) {
        $found = false;
        $i = 0;
        foreach (this.queue as $i: $object) {
            /** @psalm-suppress ArgumentTypeCoercion */
            if (
                (
                    is_string($object)
                    && $object == $class
                )
                || is_a($object, $class)
            ) {
                $found = true;
                break;
            }
        }
        if ($found) {
            return this.insertAt($i + 1, $middleware);
        }

        return this.add($middleware);
    }

    /**
     * Get the number of connected middleware layers.
     *
     * Implement the Countable interface.
     */
    size_t count() {
        return count(this.queue);
    }

    /**
     * Seeks to a given position in the queue.
     *
     * @param int $position The position to seek to.
     * @return void
     * @see \SeekableIterator::seek()
     */
    void seek($position) {
        if (!isset(this.queue[$position])) {
            throw new OutOfBoundsException("Invalid seek position ($position)");
        }

        this.position = $position;
    }

    /**
     * Rewinds back to the first element of the queue.
     *
     * @return void
     * @see \Iterator::rewind()
     */
    void rewind() {
        this.position = 0;
    }

    /**
     *  Returns the current middleware.
     *
     * @return \Psr\Http\servers.IMiddleware
     * @see \Iterator::current()
     */
    function current(): IMiddleware
    {
        if (!isset(this.queue[this.position])) {
            throw new OutOfBoundsException("Invalid current position (this.position)");
        }

<<<<<<< HEAD
        if (.queue[.position] instanceof IMiddleware) {
            return .queue[.position];
=======
        if (this.queue[this.position] instanceof MiddlewareInterface) {
            return this.queue[this.position];
>>>>>>> 0ab62ccd80e3413b8cc3cc8f15f68b7294e4e727
        }

        return this.queue[this.position] = this.resolve(this.queue[this.position]);
    }

    /**
     * Return the key of the middleware.
     *
     * @return int
     * @see \Iterator::key()
     */
    int key() {
        return this.position;
    }

    /**
     * Moves the current position to the next middleware.
     *
     * @return void
     * @see \Iterator::next()
     */
    void next() {
        ++this.position;
    }

    /**
     * Checks if current position is valid.
     *
     * @return bool
     * @see \Iterator::valid()
     */
    bool valid() {
        return isset(this.queue[this.position]);
    }
}
